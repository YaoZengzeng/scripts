#!/bin/bash

# Check if a prefix is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <namespace-prefix>"
    exit 1
fi

PREFIX="$1"

# Get all namespaces with the specified prefix
namespaces=$(kubectl get namespaces --no-headers | awk '{print $1}' | grep "^$PREFIX")

# Check if any namespaces were found
if [ -z "$namespaces" ]; then
    echo "No namespaces found with prefix '$PREFIX'."
    exit 0
fi

# Delete each namespace found
for ns in $namespaces; do
    echo "Deleting namespace: $ns"
    kubectl delete namespace "$ns"
done

echo "Deletion process completed."
