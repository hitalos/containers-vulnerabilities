#!/bin/bash

if [[ -z $1 ]]; then
	PODS=$(podman pod ls --format json | jq -r '.[] | select(.Status=="Running").Name')
else
	PODS=$(podman pod ls --format json | jq -r ".[] | select(.Status=="Running" && .Name == \"$1\").Name")
fi

for POD in $PODS; do
	CONTAINERS_QUERY="{
		name: \"$POD\",
		type: \"Pod\",
		containers: [
			.[] | select(.Names[0] |startswith(\"$POD-\")) | {
			image: .Image,
			imageID: \"sha256:\(.ImageID)\",
			name: .Names[0] | ltrimstr(\"$POD-\") }
		]
	}"

	CONTAINERS+=$(podman container ls --format json | jq -r "$CONTAINERS_QUERY")
done

mkdir -p data
echo "$CONTAINERS" | jq -s > data/pods.json
