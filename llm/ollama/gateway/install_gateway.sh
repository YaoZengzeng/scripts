#!/bin/bash

NAMESPACE="${1:-ollama}"

# Create ingress gateway
kubectl apply -f ./gateway.yaml -n "$NAMESPACE"
