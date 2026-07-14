#!/bin/bash
# Deploy the native-vLLM EPD stack and wait for it to become ready.
#
# Usage:
#   ./deploy.sh [single|2node]
#
#   single  (default) 1 GPU, all engines share one Pod
#           -> epd-deployment.yaml, Deployment: epd-disagg
#   2node   2 nodes (a 2-GPU node + a 1-GPU node): full E/P/D, one engine per
#           GPU, NO shared storage. Encode+Prefill co-located in one 2-GPU Pod
#           (share an in-Pod emptyDir EC cache); Decode on the 1-GPU node.
#           -> epd-deployment-2node.yaml, Deployments:
#              epd-ep / epd-decode / epd-proxy
#
# The mode can also be set via the MODE env var.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-${MODE:-single}}"

case "$MODE" in
  single|1|1card|onecard)
    MANIFEST="$DIR/epd-deployment.yaml"
    DEPLOYS=(epd-disagg)
    MODE="single"
    ;;
  2node|2|twonode|multinode)
    MANIFEST="$DIR/epd-deployment-2node.yaml"
    DEPLOYS=(epd-ep epd-decode epd-proxy)
    MODE="2node"
    ;;
  *)
    echo "Usage: $0 [single|2node]" >&2
    exit 1
    ;;
esac

echo ">> Mode      : $MODE"
echo ">> Manifest  : $MANIFEST"

if [[ "$MODE" == "2node" ]]; then
  echo ">> Note: needs one 2-GPU node + one 1-GPU node. No StorageClass required"
  echo ">>       (EC cache is an in-Pod emptyDir; P->D KV goes over the network)."
fi

echo ">> Applying manifests..."
kubectl apply -f "$MANIFEST"

echo ">> Waiting for rollout (model download + engines, can take a while)..."
for d in "${DEPLOYS[@]}"; do
  echo "   - deploy/$d"
  kubectl -n epd-disagg rollout status "deploy/$d" --timeout=1800s
done

echo ">> Pods:"
kubectl -n epd-disagg get pods -o wide

echo
echo "Ready. Run ./verify.sh to send a multimodal request through the EPD proxy."
echo "Tip: follow logs, e.g. ->"
if [[ "$MODE" == "2node" ]]; then
  echo "  kubectl -n epd-disagg logs -f deploy/epd-ep -c prefill"
else
  echo "  kubectl -n epd-disagg logs -f deploy/epd-disagg"
fi
