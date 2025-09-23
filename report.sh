#!/bin/bash

GRYPE_QUERY='[
	.matches[]
	| select(.vulnerability)
	| .vulnerability
	| select(.severity=="High" or .severity=="Critical")
	| {
		id: .id,
		severity: .severity | ascii_upcase,
		url: .dataSource,
		description: .description
	}
] | unique'

TRIVY_QUERY='[
	select(.Results)
	| .Results[]
	| select(.Vulnerabilities)
	| .Vulnerabilities[]
	| select(.Severity=="HIGH" or .Severity=="CRITICAL")
	| {
		id: .VulnerabilityID,
		severity: .Severity,
		url: .PrimaryURL,
		description: .Description
	}
] | unique'

rm -rf data/{trivy,grype}
mkdir -p data/{trivy,grype} static/data/{trivy,grype}

if [[ ! -f data/pods.json ]]; then
	printf "Missing file 'data/pods.json'.\nDid you ran 'list' script?\n"
	exit 1
fi

IMAGES=$(jq -r '.[].containers[].imageID' data/pods.json | sort -u)

for i in $IMAGES; do

	# Generate Trivy
	TRIVY_OUTPUT="static/data/trivy/${i//\//_}.json.zst"
	if [[ ! -f "$TRIVY_OUTPUT" && ! -s "$TRIVY_OUTPUT" ]]; then
		trivy image --format json "$i" | zstd -14 > "$TRIVY_OUTPUT"
	fi
	touch "$TRIVY_OUTPUT"
	zstdcat "$TRIVY_OUTPUT" | jq "$TRIVY_QUERY" > "data/trivy/${i//\//_}.json"

	# Generate Grype
	GRYPE_OUTPUT="static/data/grype/${i//\//_}.json.zst"
	if [[ ! -f "$GRYPE_OUTPUT" && ! -s "$GRYPE_OUTPUT" ]]; then
		grype "$i" --output json | zstd -13 > "$GRYPE_OUTPUT"
	fi
	touch "$GRYPE_OUTPUT"
	zstdcat "$GRYPE_OUTPUT" | jq "$GRYPE_QUERY" > "data/grype/${i//\//_}.json"

done

# Clean up unused files
echo "Cleaning up unused files…"
VALIDS=$(jq -r '.[] | .containers[] | .imageID + ".json.zst"' data/pods.json | tr / _)
for f in static/data/{grype,trivy}/*.json.zst; do
	filename=$(basename "$f")
	if [[ ! " ${VALIDS[*]} " =~ [[:space:]]${filename}[[:space:]] ]]; then
		echo "Removing unused file: $f"
		rm "$f"
	fi
done
