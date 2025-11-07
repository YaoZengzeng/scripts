#!/bin/bash

API_URL="${API_URL:-http://localhost:8080}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT}"
NAMESPACE="${NAMESPACE:-default}"

if [ -z "$SERVICE_ACCOUNT" ]; then
    echo "ERROR: SERVICE_ACCOUNT environment variable is required" >&2
    echo "Usage: SERVICE_ACCOUNT=<service-account> NAMESPACE=<namespace> $0" >&2
    exit 1
fi

# Generate token using kubectl
API_TOKEN=$(kubectl create token "$SERVICE_ACCOUNT" -n "$NAMESPACE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create token for service account $SERVICE_ACCOUNT in namespace $NAMESPACE" >&2
    exit 1
fi

curl -X GET "${API_URL}/v1/sandboxes" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" | jq '.'

