#!/bin/bash

NAMESPACE="kmesh-system"
NODE_NAME="kmesh-testing-worker"

PODS=$(kubectl get pods -n $NAMESPACE --field-selector spec.nodeName=$NODE_NAME -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
  echo "No pods found on node $NODE_NAME in namespace $NAMESPACE."
  exit 1
fi

for POD in $PODS; do
  echo "Debug log for Pod: $POD"
  kmeshctl log $POD --set default:debug
  kmeshctl log $POD --set bpf:debug
  echo "----------------------------------------"
done
