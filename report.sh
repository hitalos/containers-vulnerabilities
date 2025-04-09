#!/bin/bash

# shellcheck disable=SC2016
PODS_QUERY='[
	.items as $items
	| .items
	| map(.metadata.namespace) | unique | .[]
	| . as $namespace
	| {
		namespace: $namespace,
		containers: [
			$items[]
			| select(.metadata.namespace==$namespace)
			| .status.containerStatuses[]
			| { image: .image, imageID: .imageID, name: .name }
		] | unique
	}
]'

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

mkdir -p data/{trivy,grype} static/data/{trivy,grype}

kubectl get pods -A -o json | jq -r "$PODS_QUERY" > data/pods.json

IMAGES=$(jq -r '.[].containers[].imageID' data/pods.json | sort -u)

for i in $IMAGES; do

	# Generate Trivy
	TRIVY_OUTPUT="static/data/trivy/${i//\//_}.json.zst"
	if [[ ! -f "$TRIVY_OUTPUT" && ! -s "$TRIVY_OUTPUT" ]]; then
		trivy image --format json "$i" | zstd -14 > "$TRIVY_OUTPUT"
	fi
	zstdcat "$TRIVY_OUTPUT" | jq "$TRIVY_QUERY" > "data/trivy/${i//\//_}.json"

	# Generate Grype
	GRYPE_OUTPUT="static/data/grype/${i//\//_}.json.zst"
	if [[ ! -f "$GRYPE_OUTPUT" && ! -s "$GRYPE_OUTPUT" ]]; then
		grype "$i" --output json | zstd -13 > "$GRYPE_OUTPUT"
	fi
	zstdcat "$GRYPE_OUTPUT" | jq "$GRYPE_QUERY" > "data/grype/${i//\//_}.json"

done
