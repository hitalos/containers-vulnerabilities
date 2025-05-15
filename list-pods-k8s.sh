#!/bin/bash

# shellcheck disable=SC2016
PODS_QUERY='[
	.items as $items
	| .items
	| map(.metadata.namespace) | unique | .[]
	| . as $namespace
	| {
		name: $namespace,
		type: "Namespace",
		containers: [
			$items[]
			| select(.metadata.namespace==$namespace and .status.phase=="Running")
			| .status.containerStatuses[]
			| { image: .image, imageID: .imageID, name: .name }
		] | unique
	}
]'

if [[ -z $1 ]]; then
	PODS=$(kubectl --request-timeout 1s get pods -A -o json)
else
	PODS=$(kubectl --request-timeout 1s get pods -n "$1" -o json)
fi

if [[ "$?" == "0" && -n "$PODS" ]]; then
	echo "$PODS" | jq -r "$PODS_QUERY" > data/pods.json
else
	echo "Error updating pods.json. Using previous data."
fi
