#!/bin/bash

NAMESPACE="${1:-ollama}"

# Create ingress gateway
kubectl apply -f ./istio_gateway.yaml -n "$NAMESPACE"
