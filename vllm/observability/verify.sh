#!/bin/bash
# Verify vLLM observability stack is working.
# Checks ServiceMonitors, Grafana dashboards, and Prometheus Adapter custom metrics.

set -euo pipefail

PASS="[OK]"
WARN="[WARN]"
FAIL="[FAIL]"

echo "============================================"
echo "  vLLM Observability Stack Verification"
echo "============================================"

# 1. Check Prometheus Operator
echo ""
echo "--- Prometheus Operator ---"
if kubectl get pods -A 2>/dev/null | grep -q "prome.*operator"; then
  echo "$PASS Prometheus Operator is running"
else
  echo "$FAIL Prometheus Operator not found"
fi

# 2. Check Grafana
echo ""
echo "--- Grafana ---"
GRAFANA_POD=$(kubectl get pods -A --no-headers 2>/dev/null | grep grafana | head -1)
if [[ -n "$GRAFANA_POD" ]]; then
  GRAFANA_NS=$(echo "$GRAFANA_POD" | awk '{print $1}')
  GRAFANA_STATUS=$(echo "$GRAFANA_POD" | awk '{print $4}')
  echo "$PASS Grafana pod found (namespace: $GRAFANA_NS, status: $GRAFANA_STATUS)"
else
  echo "$FAIL Grafana pod not found"
fi

# 3. Check ServiceMonitors & PodMonitors
echo ""
echo "--- ServiceMonitors ---"
SM_COUNT=$(kubectl get servicemonitors -A --no-headers 2>/dev/null | wc -l)
VLLM_SM=$(kubectl get servicemonitors -A --no-headers 2>/dev/null | grep -i vllm || true)
echo "$PASS $SM_COUNT ServiceMonitor(s) found"
if [[ -n "$VLLM_SM" ]]; then
  echo "$PASS vLLM ServiceMonitor detected:"
  echo "$VLLM_SM" | awk '{print "    "$1"/"$2}'
fi

echo ""
echo "--- PodMonitors ---"
PM_COUNT=$(kubectl get podmonitors -A --no-headers 2>/dev/null | wc -l)
VLLM_PM=$(kubectl get podmonitors -A --no-headers 2>/dev/null | grep -i vllm || true)
echo "$PASS $PM_COUNT PodMonitor(s) found"
if [[ -n "$VLLM_PM" ]]; then
  echo "$PASS vLLM PodMonitor detected:"
  echo "$VLLM_PM" | awk '{print "    "$1"/"$2}'
else
  echo "$WARN No vLLM PodMonitor found — run install.sh to create one"
fi

# 4. Check Grafana dashboard ConfigMaps
echo ""
echo "--- Grafana Dashboards ---"
DASHBOARD_COUNT=$(kubectl get configmaps -A -l grafana_dashboard=1 --no-headers 2>/dev/null | wc -l)
VLLM_DASHBOARDS=$(kubectl get configmaps -A -l grafana_dashboard=1 --no-headers 2>/dev/null | grep -i vllm || true)
echo "$PASS $DASHBOARD_COUNT Grafana dashboard ConfigMap(s) loaded"
if [[ -n "$VLLM_DASHBOARDS" ]]; then
  echo "$PASS vLLM dashboard(s):"
  echo "$VLLM_DASHBOARDS" | awk '{print "    "$1"/"$2}'
else
  echo "$WARN No vLLM-specific dashboard ConfigMap found (you can import one manually in Grafana)"
fi

# 5. Check vLLM pods & scrape targets
echo ""
echo "--- vLLM Pods ---"
VLLM_PODS=$(kubectl get pods -A --no-headers 2>/dev/null | grep -i vllm | grep -v grafana || true)
if [[ -n "$VLLM_PODS" ]]; then
  VLLM_POD_COUNT=$(echo "$VLLM_PODS" | wc -l)
  echo "$PASS $VLLM_POD_COUNT vLLM pod(s) found:"
  echo "$VLLM_PODS" | awk '{print "    "$1"/"$2" ("$4")"}'
else
  echo "$WARN No vLLM pods found — deploy vLLM serving engines to start scraping metrics"
fi

echo ""
echo "--- Prometheus Scrape Targets ---"
PROM_SVC=$(kubectl get svc -A --no-headers 2>/dev/null | grep -E "prome.*prometheus " | head -1)
if [[ -n "$PROM_SVC" ]]; then
  PROM_NS=$(echo "$PROM_SVC" | awk '{print $1}')
  PROM_NAME=$(echo "$PROM_SVC" | awk '{print $2}')
  VLLM_TARGETS=$(kubectl exec -n "$PROM_NS" -c prometheus prometheus-kube-prom-stack-kube-prome-prometheus-0 -- wget -qO- http://localhost:9090/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[]? | select(.labels.job // "" | test("vllm|pod-monitor")) | "\(.labels.job) -> \(.scrapeUrl) (\(.health))"' 2>/dev/null || true)
  if [[ -n "$VLLM_TARGETS" ]]; then
    echo "$PASS Prometheus is scraping vLLM targets:"
    echo "$VLLM_TARGETS" | while read -r t; do echo "    $t"; done
  else
    echo "$WARN No vLLM scrape targets in Prometheus yet"
  fi
else
  echo "$WARN Cannot check — Prometheus service not found"
fi

# 6. Check Prometheus Adapter / custom metrics
echo ""
echo "--- Prometheus Adapter (Custom Metrics) ---"
ADAPTER_POD=$(kubectl get pods -A --no-headers 2>/dev/null | grep prometheus-adapter | head -1)
if [[ -n "$ADAPTER_POD" ]]; then
  echo "$PASS Prometheus Adapter is running"
  VLLM_METRICS=$(kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1/namespaces/default/metrics 2>/dev/null | jq -r '.items[]?.name // empty' 2>/dev/null | grep vllm || true)
  if [[ -n "$VLLM_METRICS" ]]; then
    echo "$PASS vLLM custom metrics available:"
    echo "$VLLM_METRICS" | while read -r m; do echo "    $m"; done
  else
    echo "$WARN No vLLM custom metrics yet — metrics appear after vLLM pods start serving requests"
  fi
else
  echo "$WARN Prometheus Adapter not installed (needed for HPA autoscaling, not required for dashboards)"
fi

echo ""
echo "============================================"
echo "  Summary"
echo "============================================"
echo "  Prometheus:    $(kubectl get svc -A --no-headers 2>/dev/null | grep -c "prome.*prometheus " || echo 0) service(s)"
echo "  Grafana:       $(kubectl get svc -A --no-headers 2>/dev/null | grep -c grafana || echo 0) service(s)"
echo "  Dashboards:    $DASHBOARD_COUNT ConfigMap(s)"
echo "  PodMonitors:   $PM_COUNT"
echo "  vLLM pods:     $(echo "$VLLM_PODS" | grep -c . 2>/dev/null || echo 0)"
echo "  vLLM dashboard: $(if [[ -n "$VLLM_DASHBOARDS" ]]; then echo "loaded"; else echo "not found"; fi)"
echo "============================================"
