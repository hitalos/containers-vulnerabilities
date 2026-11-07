#!/bin/bash

# shellcheck disable=SC2016
PODS_QUERY='[
	.items
	| map(select(.status.phase=="Running"))
	| group_by(.metadata.namespace)[]
	| {
		name: .[0].metadata.namespace,
		type: "Namespace",
		containers: [
			.[].status.containerStatuses[]
			| {
				name,
				image,
				imageID: (if (.imageID // "" | contains("sha256")) then .imageID else .image end),
			}
		] | unique
	}
]'

if [[ -z $1 ]]; then
	PODS=$(kubectl --request-timeout 1s get pods -A -o json)
else
	PODS=$(kubectl --request-timeout 1s get pods -n "$1" -o json)
fi

if [[ "$?" == "0" && -n "$PODS" ]]; then
	mkdir -p data/
	jq -r "$PODS_QUERY" <<< "$PODS" > data/pods.json
else
	echo "Error updating pods.json. Using previous data."
fi
