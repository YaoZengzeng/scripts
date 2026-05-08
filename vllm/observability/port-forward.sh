#!/bin/bash
# Port-forward Grafana and Prometheus dashboards to local machine.
#
# Usage:
#   bash port-forward.sh              # auto-detect services across all namespaces
#   bash port-forward.sh [ns]         # look in a specific namespace

set -euo pipefail

NAMESPACE="${1:-}"

# Auto-detect Grafana service
if [[ -n "$NAMESPACE" ]]; then
  GRAFANA_INFO=$(kubectl get svc -n "$NAMESPACE" -o name 2>/dev/null | grep grafana | head -1)
  GRAFANA_NS="$NAMESPACE"
else
  GRAFANA_INFO=$(kubectl get svc -A --no-headers 2>/dev/null | grep grafana | head -1)
  GRAFANA_NS=$(echo "$GRAFANA_INFO" | awk '{print $1}')
  GRAFANA_INFO="svc/$(echo "$GRAFANA_INFO" | awk '{print $2}')"
fi

if [[ -z "$GRAFANA_INFO" ]]; then
  echo "ERROR: No Grafana service found in the cluster."
  exit 1
fi

# Auto-detect Prometheus service
if [[ -n "$NAMESPACE" ]]; then
  PROM_INFO=$(kubectl get svc -n "$NAMESPACE" -o name 2>/dev/null | grep -E "prometheus.*prometheus$|prometheus-operated" | head -1)
  PROM_NS="$NAMESPACE"
else
  PROM_INFO=$(kubectl get svc -A --no-headers 2>/dev/null | grep -E "prome.*prometheus " | head -1)
  PROM_NS=$(echo "$PROM_INFO" | awk '{print $1}')
  PROM_INFO="svc/$(echo "$PROM_INFO" | awk '{print $2}')"
fi

echo "Forwarding Grafana dashboard to http://localhost:3000"
echo "  Detected: $GRAFANA_INFO (namespace: $GRAFANA_NS)"
echo "  Default user: admin"
kubectl --namespace "$GRAFANA_NS" port-forward "$GRAFANA_INFO" 3000:80 --address 0.0.0.0 &

if [[ -n "$PROM_INFO" ]]; then
  echo "Forwarding Prometheus dashboard to http://localhost:9090"
  echo "  Detected: $PROM_INFO (namespace: $PROM_NS)"
  kubectl --namespace "$PROM_NS" port-forward "$PROM_INFO" 9090:9090 --address 0.0.0.0 &
else
  echo "WARNING: No Prometheus service found, skipping."
fi

wait
