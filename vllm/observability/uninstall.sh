#!/bin/bash
# Uninstall the vLLM observability stack.
#
# For the integrated approach (vllm-stack subchart), disable observability
# by upgrading with observability turned off:
#   helm upgrade <release> vllm-stack/vllm-stack --reuse-values --set kube-prometheus-stack.enabled=false
#
# For the standalone legacy approach (STANDALONE=1 bash install.sh):

set -euo pipefail

RELEASE_NAME="${1:-llmstack}"
NAMESPACE="${2:-default}"

if [[ "${STANDALONE:-0}" == "1" ]]; then
  echo "==> Uninstalling standalone kube-prometheus-stack (legacy mode)"
  helm uninstall prometheus-adapter -n monitoring 2>/dev/null || true
  helm uninstall kube-prom-stack -n monitoring 2>/dev/null || true
  echo "==> Done"
  exit 0
fi

echo "==> Disabling observability on vllm-stack release: $RELEASE_NAME (namespace: $NAMESPACE)"
helm upgrade "$RELEASE_NAME" vllm-stack/vllm-stack \
  --namespace "$NAMESPACE" \
  --reuse-values \
  --set kube-prometheus-stack.enabled=false \
  --set prometheus-adapter.enabled=false \
  --set grafanaDashboards.enabled=false \
  --set servingEngineSpec.serviceMonitor.enabled=false \
  --set routerSpec.serviceMonitor.enabled=false \
  --wait

echo "==> Observability disabled on release $RELEASE_NAME"
