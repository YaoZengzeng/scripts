#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: SERVICE_ACCOUNT=<service-account> NAMESPACE=<namespace> $0 <sandboxId>" >&2
    exit 1
fi

SANDBOX_ID="$1"
API_URL="${API_URL:-http://localhost:8080}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT}"
NAMESPACE="${NAMESPACE:-default}"

if [ -z "$SERVICE_ACCOUNT" ]; then
    echo "ERROR: SERVICE_ACCOUNT environment variable is required" >&2
    exit 1
fi

# Generate token using kubectl
API_TOKEN=$(kubectl create token "$SERVICE_ACCOUNT" -n "$NAMESPACE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create token for service account $SERVICE_ACCOUNT in namespace $NAMESPACE" >&2
    exit 1
fi

curl -X DELETE "${API_URL}/v1/sandboxes/${SANDBOX_ID}" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" | jq '.'

