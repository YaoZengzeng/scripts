#!/bin/bash
# Deploy the single-GPU native-vLLM EPD stack and wait for it to become ready.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

echo ">> Applying manifests..."
kubectl apply -f "$DIR/epd-deployment.yaml"

echo ">> Waiting for rollout (model download + 3 engines, can take a while)..."
kubectl -n epd-disagg rollout status deploy/epd-disagg --timeout=1800s

echo ">> Pods:"
kubectl -n epd-disagg get pods -o wide

echo
echo "Ready. Run ./verify.sh to send a multimodal request through the EPD proxy."
echo "Tip: follow logs with ->  kubectl -n epd-disagg logs -f deploy/epd-disagg"
