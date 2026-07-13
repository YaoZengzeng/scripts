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
#   4. Decide success two ways (either is sufficient):
#      (a) Metrics (definitive): offload byte counters (vllm:kv_offload_*) grew.
#          The pinned image (vllm/vllm-openai:v0.24.0+) exposes these, so this
#          is the primary check.
#      (b) Latency (version-independent fallback): the evicted prefix, when
#          replayed, is served much faster than a fresh full recompute -> it was
#          loaded back from the CPU offload tier instead of being recomputed.
#
# Usage:  ./verify-offloading.sh
# =============================================================================
set -uo pipefail

NAMESPACE="vllm-offloading"
DEPLOY="vllm-qwen-offloading"
SVC="vllm-qwen-offloading"
MODEL="Qwen/Qwen3-0.6B"
SVC_PORT="8000"
BASE=""  # resolved from the LoadBalancer ingress below

# ---- Color output ---------------------------------------------------------
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
hr()    { printf '%s\n' "------------------------------------------------------------"; }

# ---- 1. Wait for the deployment to be ready -------------------------------
blue "[1/6] Waiting for Deployment/${DEPLOY} to become ready (pulling image + downloading model may take a while)..."
if ! kubectl -n "${NAMESPACE}" rollout status deploy/"${DEPLOY}" --timeout=900s; then
  red "Deployment not ready, please check: kubectl -n ${NAMESPACE} describe deploy/${DEPLOY}"
  exit 1
fi
POD=$(kubectl -n "${NAMESPACE}" get pod -l app="${DEPLOY}" -o jsonpath='{.items[0].metadata.name}')
green "Pod: ${POD}"

# ---- 2. Resolve the LoadBalancer endpoint ---------------------------------
blue "[2/6] Waiting for the LoadBalancer external address of svc/${SVC} ..."
LB_ADDR=""
for _ in $(seq 1 60); do
  LB_ADDR=$(kubectl -n "${NAMESPACE}" get svc "${SVC}" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [[ -z "${LB_ADDR}" ]]; then
    # Some providers publish a hostname instead of an IP.
    LB_ADDR=$(kubectl -n "${NAMESPACE}" get svc "${SVC}" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  fi
  [[ -n "${LB_ADDR}" ]] && break
  sleep 5
done
if [[ -z "${LB_ADDR}" ]]; then
  red "LoadBalancer external address not assigned yet."
  red "Check: kubectl -n ${NAMESPACE} get svc ${SVC}"
  red "If your cluster has no LoadBalancer provider, install one (e.g. MetalLB) or fall back to port-forward."
  exit 1
fi
BASE="http://${LB_ADDR}:${SVC_PORT}"
green "LoadBalancer endpoint: ${BASE}"

blue "      Waiting for vLLM to be reachable at ${BASE}/v1/models ..."
for _ in $(seq 1 60); do
  if curl -s "${BASE}/v1/models" >/dev/null 2>&1; then break; fi
  sleep 2
done
if ! curl -s "${BASE}/v1/models" >/dev/null 2>&1; then
  red "Cannot reach vLLM /v1/models at ${BASE}"
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
# Sum the sample values of every line matching an extended regex, ignoring the
# per-counter `_created` timestamp lines (which would otherwise dwarf the sum).
metric_sum() {
  local pattern="$1"
  curl -s "${BASE}/metrics" 2>/dev/null \
    | grep -E "${pattern}" | grep -vE '_created' \
    | awk '{s+=$NF} END{printf "%.0f", s+0}'
}

# Total bytes transferred to/from the CPU offload tier.
# The vLLM OffloadingConnector exposes flat counters
#   vllm:kv_offload_store_bytes  (GPU -> CPU, on eviction)
#   vllm:kv_offload_load_bytes   (CPU -> GPU, on cache hit)
# and a deprecated aggregate vllm:kv_offload_total_bytes (transfer_type label).
# Some builds suffix counters with `_total`; match both. Prefer the flat
# counters and fall back to the deprecated aggregate when they are absent.
offload_bytes() {
  local flat depr
  flat=$(metric_sum '^vllm:kv_offload_(store|load)_bytes(_total)?[ {]')
  if [[ "${flat}" -gt 0 ]]; then
    echo "${flat}"
    return
  fi
  depr=$(metric_sum '^vllm:kv_offload_total_bytes(_total)?[ {]')
  echo "${depr}"
}

show_offload_metrics() {
  curl -s "${BASE}/metrics" 2>/dev/null \
    | grep -iE 'offload|kv_connector|external' | grep -vE '_created|_bucket|^#' \
    | sed 's/^/    /' || true
}

# Unique per-run id so prefixes are cold across repeated script executions.
RUN_ID="$(date +%s)"

# Build a long prompt for a given tag. Keep it safely BELOW the single-request
# GPU capacity (512 blocks * 16 = 8192 tokens) so the request can be scheduled;
# offloading is triggered by the AGGREGATE of many distinct prefixes overflowing
# the GPU cache, not by one oversized request.
build_prompt() {
  local tag="$1" chunk i out
  out="UNIQUE-PREFIX-${RUN_ID}-${tag} :: "
  # ~ 200 * 13 words ~= 3400 tokens (well under the 8192 GPU cap).
  chunk="alice met bob and then they walked together through the quiet old town. "
  for i in $(seq 1 200); do out+="${chunk}"; done
  printf '%s' "${out}"
}

# Send one request and print ONLY the total wall time in seconds (float).
send_timed() {
  local tag="$1" prompt
  prompt="$(build_prompt "${tag}")"
  jq -n --arg m "${MODEL}" --arg p "${prompt}" \
     '{model:$m, prompt:$p, max_tokens:1, temperature:0}' \
    | curl -s --max-time 180 -o /dev/null -w '%{time_total}' \
        "${BASE}/v1/completions" \
        -H 'Content-Type: application/json' -d @-
}

# Fire-and-forget send (used to flood/evict); ignores the response.
send_fire() {
  local tag="$1" prompt
  prompt="$(build_prompt "${tag}")"
  jq -n --arg m "${MODEL}" --arg p "${prompt}" \
     '{model:$m, prompt:$p, max_tokens:1, temperature:0}' \
    | curl -s --max-time 180 -o /dev/null \
        "${BASE}/v1/completions" \
        -H 'Content-Type: application/json' -d @- >/dev/null 2>&1
}

# less_than A B  -> exit 0 if A < B (float compare).
less_than() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a < b)}'; }

# ---- 4. Metric baseline + cold/GPU-hit latency baselines ------------------
blue "[4/6] Recording baselines..."
OFFLOAD_BEFORE=$(offload_bytes)
HITS_BEFORE=$(metric_sum '^vllm:prefix_cache_hits_total[ {]')
echo "    offload bytes (store+load) (before) = ${OFFLOAD_BEFORE}"
echo "    prefix_cache_hits          (before) = ${HITS_BEFORE}"

echo "    -> COLD  request X (first time, full prefill)"
T_COLD=$(send_timed "X")
echo "       t_cold      = ${T_COLD}s"

echo "    -> RESEND request X (should hit GPU cache, fastest)"
T_HIT=$(send_timed "X")
echo "       t_gpu_hit   = ${T_HIT}s"

# ---- 5. Evict X from GPU, then replay it ----------------------------------
blue "[5/6] Flooding with distinct prefixes to evict X from the GPU cache..."
for tag in E1 E2 E3 E4 E5 E6 E7 E8; do
  echo "    -> evictor ${tag}"
  send_fire "${tag}"
done

echo "    -> REPLAY request X (evicted from GPU; loaded from CPU if offloading works)"
T_WARM=$(send_timed "X")
echo "       t_warm      = ${T_WARM}s"

echo "    -> NEW  request Z (brand-new prefix, guaranteed full recompute reference)"
T_RECOMP=$(send_timed "Z")
echo "       t_recompute = ${T_RECOMP}s"

sleep 3

# ---- 6. Compare and decide ------------------------------------------------
blue "[6/6] Collecting final metrics and deciding..."
OFFLOAD_AFTER=$(offload_bytes)
HITS_AFTER=$(metric_sum '^vllm:prefix_cache_hits_total[ {]')

hr
echo "offloading-related metrics (current values):"
METRICS_DUMP="$(show_offload_metrics)"
if [[ -n "${METRICS_DUMP}" ]]; then
  echo "${METRICS_DUMP}"
else
  echo "    (this vLLM build exposes no offload/connector metrics)"
fi
hr
echo "  offload bytes (store+load): before=${OFFLOAD_BEFORE}  after=${OFFLOAD_AFTER}"
echo "  prefix_cache_hits         : before=${HITS_BEFORE}  after=${HITS_AFTER}"
echo "  latency: cold=${T_COLD}s  gpu_hit=${T_HIT}s  warm(evicted)=${T_WARM}s  recompute=${T_RECOMP}s"
hr

PASS=0

# Signal 1 (definitive): offload byte counters grew.
if [[ "${OFFLOAD_AFTER}" -gt 0 && "${OFFLOAD_AFTER}" -gt "${OFFLOAD_BEFORE}" ]]; then
  green "✔ offload bytes grew from ${OFFLOAD_BEFORE} to ${OFFLOAD_AFTER}: KV spilled to / pulled back from CPU."
  PASS=1
fi

# Signal 2 (latency, version-independent): the evicted prefix, when replayed,
# is served clearly faster than a fresh full prefill -> it came back from CPU
# instead of being fully recomputed. Require t_warm < 70% of the recompute
# reference (and of the cold time) to avoid noise.
THRESH_RECOMP=$(awk -v r="${T_RECOMP}" 'BEGIN{printf "%.4f", r*0.7}')
THRESH_COLD=$(awk -v c="${T_COLD}" 'BEGIN{printf "%.4f", c*0.7}')
if less_than "${T_WARM}" "${THRESH_RECOMP}" && less_than "${T_WARM}" "${THRESH_COLD}"; then
  green "✔ replayed evicted prefix was ~$(awk -v w="${T_WARM}" -v r="${T_RECOMP}" 'BEGIN{printf "%.0f%%", (1-w/r)*100}') faster than a full recompute: served from the CPU offload tier."
  PASS=1
fi

if [[ "${HITS_AFTER}" -gt "${HITS_BEFORE}" ]]; then
  green "✔ prefix cache hits increased (${HITS_BEFORE} -> ${HITS_AFTER})."
fi

echo
if [[ "${PASS}" -eq 1 ]]; then
  green "==================== Conclusion: native offloading is WORKING ✔ ===================="
  exit 0
else
  red   "==================== Conclusion: offloading not confirmed ✗ ===================="
  red   "latency: cold=${T_COLD}s warm(evicted)=${T_WARM}s recompute=${T_RECOMP}s"
  red   "If t_warm is close to t_recompute, the evicted prefix was recomputed (offloading not helping)."
  red   "Troubleshooting tips:"
  red   "  1) Confirm the deployment args include OffloadingConnector and the Pod restarted with the new config."
  red   "  2) GPU cache too large -> no eviction. Lower --num-gpu-blocks-override, or add more evictor requests."
  red   "  3) Inspect any metrics: curl -s ${BASE}/metrics | grep -iE 'offload|connector|external'"
  red   "  4) Check logs:          kubectl -n ${NAMESPACE} logs ${POD} | grep -i offload"
  exit 1
fi
