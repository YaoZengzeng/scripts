#!/usr/bin/env bash
# =============================================================================
# Verify that vLLM native (OffloadingConnector) KV-cache offloading is working
#
# How it works:
#   1. The deployment uses --num-gpu-blocks-override 512 to shrink the GPU KV
#      cache to a tiny size (~8K tokens).
#   2. First send several long requests with DISTINCT prefixes -> fill the GPU
#      KV cache and trigger eviction. Evicted KV blocks are offloaded (stored)
#      to CPU RAM by the OffloadingConnector.
#   3. Then replay the 1st long request -> its KV is no longer on the GPU, but
#      it is in the CPU offload pool, so it should be pulled back (loaded) from
#      CPU instead of being recomputed.
#   4. Decide success by the before/after delta of the offload-related counters
#      in /metrics plus the prefix cache hit count, and by checking the
#      OffloadingConnector init messages in the Pod logs.
#
# Usage:  ./verify-offloading.sh
# =============================================================================
set -uo pipefail

NAMESPACE="vllm-offloading"
DEPLOY="vllm-qwen-offloading"
SVC="vllm-qwen-offloading"
MODEL="Qwen/Qwen3-0.6B"
LOCAL_PORT="18000"
BASE="http://127.0.0.1:${LOCAL_PORT}"

# ---- Color output ---------------------------------------------------------
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
hr()    { printf '%s\n' "------------------------------------------------------------"; }

PF_PID=""
cleanup() {
  [[ -n "${PF_PID}" ]] && kill "${PF_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ---- 1. Wait for the deployment to be ready -------------------------------
blue "[1/6] Waiting for Deployment/${DEPLOY} to become ready (pulling image + downloading model may take a while)..."
if ! kubectl -n "${NAMESPACE}" rollout status deploy/"${DEPLOY}" --timeout=900s; then
  red "Deployment not ready, please check: kubectl -n ${NAMESPACE} describe deploy/${DEPLOY}"
  exit 1
fi
POD=$(kubectl -n "${NAMESPACE}" get pod -l app="${DEPLOY}" -o jsonpath='{.items[0].metadata.name}')
green "Pod: ${POD}"

# ---- 2. Port-forward -------------------------------------------------------
blue "[2/6] Setting up port-forward svc/${SVC} 8000 -> localhost:${LOCAL_PORT} ..."
kubectl -n "${NAMESPACE}" port-forward "svc/${SVC}" "${LOCAL_PORT}:8000" >/dev/null 2>&1 &
PF_PID=$!
for _ in $(seq 1 30); do
  if curl -s "${BASE}/v1/models" >/dev/null 2>&1; then break; fi
  sleep 1
done
if ! curl -s "${BASE}/v1/models" >/dev/null 2>&1; then
  red "Cannot reach vLLM /v1/models"
  exit 1
fi
green "vLLM is reachable."

# ---- 3. Check OffloadingConnector init in the logs ------------------------
blue "[3/6] Checking Pod logs for offloading connector init messages..."
hr
LOG_HIT=$(kubectl -n "${NAMESPACE}" logs "${POD}" --tail=-1 2>/dev/null \
          | grep -iE 'offload|OffloadingConnector' | head -n 15)
if [[ -n "${LOG_HIT}" ]]; then
  echo "${LOG_HIT}"
  green "OffloadingConnector-related messages detected in the logs."
else
  red "No 'offload' string found in the logs (may be log level / version differences; continue via metrics)."
fi
hr

# ---- Helper: aggregate metrics from /metrics ------------------------------
# Match a metric name (regex), sum the values of all matching samples;
# ignore comment lines.
metric_sum() {
  local pattern="$1"
  curl -s "${BASE}/metrics" 2>/dev/null \
    | grep -E "^vllm:.*(${pattern})" | grep -v '^#' \
    | awk '{s+=$NF} END{printf "%.0f", s+0}'
}

show_offload_metrics() {
  curl -s "${BASE}/metrics" 2>/dev/null \
    | grep -iE 'offload|kv_connector|external_prefix' | grep -v '^#' \
    | sed 's/^/    /' || true
}

# Send one long request (~8K tokens) with a unique prefix to trigger/hit the KV cache
send_long_request() {
  local tag="$1"
  local prompt
  prompt="UNIQUE-PREFIX-${tag} :: "
  # ~ 700 * 11 ~= 7700 tokens, close to the GPU 512-block (~8192-token) capacity
  local chunk="alice met bob and then they walked together through the quiet old town. "
  local i
  for i in $(seq 1 700); do prompt+="${chunk}"; done

  jq -n --arg m "${MODEL}" --arg p "${prompt}" \
     '{model:$m, prompt:$p, max_tokens:1, temperature:0}' \
    | curl -s "${BASE}/v1/completions" \
        -H 'Content-Type: application/json' -d @- >/dev/null 2>&1
}

# ---- 4. Record baseline metrics -------------------------------------------
blue "[4/6] Recording baseline metrics..."
OFFLOAD_BEFORE=$(metric_sum 'offload')
HITS_BEFORE=$(metric_sum 'prefix_cache_hits_total')
echo "    offload counters total   (before) = ${OFFLOAD_BEFORE}"
echo "    prefix_cache_hits         (before) = ${HITS_BEFORE}"

# ---- 5. Force eviction + hit the offload pool -----------------------------
blue "[5/6] Sending several distinct-prefix long requests to fill and evict the GPU KV cache..."
for tag in A B C D E F; do
  echo "    -> sending long request ${tag}"
  send_long_request "${tag}"
done

blue "      Replaying request A (its KV should already be evicted to CPU, now pulled back and hit)..."
send_long_request "A"
send_long_request "A"

sleep 3

# ---- 6. Compare metrics and decide ----------------------------------------
blue "[6/6] Collecting final metrics and deciding..."
OFFLOAD_AFTER=$(metric_sum 'offload')
HITS_AFTER=$(metric_sum 'prefix_cache_hits_total')

hr
echo "offloading-related metrics (current values):"
show_offload_metrics
hr
echo "  offload counters total: before=${OFFLOAD_BEFORE}  after=${OFFLOAD_AFTER}"
echo "  prefix_cache_hits     : before=${HITS_BEFORE}  after=${HITS_AFTER}"
hr

PASS=0
if [[ "${OFFLOAD_AFTER}" -gt 0 && "${OFFLOAD_AFTER}" -gt "${OFFLOAD_BEFORE}" ]]; then
  green "✔ offloading metrics grew from ${OFFLOAD_BEFORE} to ${OFFLOAD_AFTER}: KV was spilled/pulled back via CPU."
  PASS=1
fi
if [[ "${HITS_AFTER}" -gt "${HITS_BEFORE}" ]]; then
  green "✔ prefix cache hits increased (${HITS_BEFORE} -> ${HITS_AFTER}): the replayed request hit the cache."
fi

echo
if [[ "${PASS}" -eq 1 ]]; then
  green "==================== Conclusion: native offloading is WORKING ✔ ===================="
  exit 0
else
  red   "==================== Conclusion: no offloading growth observed ✗ ===================="
  red   "Troubleshooting tips:"
  red   "  1) Confirm the deployment args include OffloadingConnector and the Pod restarted with the new config."
  red   "  2) If the GPU is too large there is no eviction -> keep/lower --num-gpu-blocks-override."
  red   "  3) Check metric names: curl -s ${BASE}/metrics | grep -i offload"
  red   "  4) Check logs:         kubectl -n ${NAMESPACE} logs ${POD} | grep -i offload"
  exit 1
fi
