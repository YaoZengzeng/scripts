#!/bin/bash
# Install vLLM observability stack via vllm-stack helm chart.
#
# The observability stack (Prometheus, Grafana, ServiceMonitor, dashboards)
# is now built into the vllm-stack helm chart as a subchart.
# Ref: https://github.com/vllm-project/production-stack/blob/main/helm/README.md#observability
#
# Usage:
#   bash install.sh                    # upgrade existing vllm-stack release with observability
#   bash install.sh <release> [ns]     # specify release name and namespace
#   STANDALONE=1 bash install.sh       # legacy standalone kube-prometheus-stack install

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RELEASE_NAME="${1:-llmstack}"
NAMESPACE="${2:-default}"

if [[ "${STANDALONE:-0}" == "1" ]]; then
  echo "==> Installing standalone kube-prometheus-stack (legacy mode)"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    -f "$SCRIPT_DIR/kube-prom-stack.yaml" --wait

  helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
    --namespace monitoring \
    --create-namespace \
    -f "$SCRIPT_DIR/prom-adapter.yaml"

  echo "==> Done. Grafana: svc/kube-prom-stack-grafana in monitoring namespace"
  echo "    Default credentials: admin / prom-operator"
  exit 0
fi

echo "==> Enabling observability on vllm-stack release: $RELEASE_NAME (namespace: $NAMESPACE)"
helm upgrade "$RELEASE_NAME" vllm-stack/vllm-stack \
  --namespace "$NAMESPACE" \
  --reuse-values \
  -f "$SCRIPT_DIR/observability-values.yaml" \
  --wait

echo "==> Done. Grafana: svc/${RELEASE_NAME}-grafana in $NAMESPACE namespace"
echo "    Run 'bash port-forward.sh $RELEASE_NAME $NAMESPACE' to access dashboards"
