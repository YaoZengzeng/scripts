#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Benchmark and verify the precise prefix cache aware routing in llm-d.
#
# Modes:
#   test       — Quick manual verification: send two identical requests and
#                check that the scheduler returns a non-zero prefix-cache score
#                on the second request (proving the KV-cache was reused).
#   benchmark  — Full inference-perf benchmark using the guide.yaml template
#                from llm-d/llm-d. Requires a PVC for storing results.
#
# Usage:
#   ./benmark.sh test
#   ./benmark.sh benchmark
#
# Environment variables:
#   NAMESPACE            (default: llm-d)
#   MODEL_NAME           (default: Qwen/Qwen3-0.6B)
#   RELEASE_NAME_POSTFIX (default: kv-events)
#   GATEWAY_PORT         (default: 8000)   local port for port-forward
#   BENCHMARK_PVC        (default: workload-pvc)
#   BENCHMARK_IMAGE      (default: ghcr.io/llm-d/llm-d-benchmark:v0.5.2)

set +x
set -e
set -o pipefail

# --------------------------------------------------------------------------- #
# Colour helpers
# --------------------------------------------------------------------------- #
COLOR_RESET=$'\e[0m'
COLOR_GREEN=$'\e[32m'
COLOR_RED=$'\e[31m'
COLOR_YELLOW=$'\e[33m'

log_success() { echo "${COLOR_GREEN}✅ $*${COLOR_RESET}"; }
log_error()   { echo "${COLOR_RED}❌ $*${COLOR_RESET}" >&2; }
log_info()    { echo "ℹ️  $*"; }
log_warn()    { echo "${COLOR_YELLOW}⚠️  $*${COLOR_RESET}"; }

# --------------------------------------------------------------------------- #
# Pre-flight
# --------------------------------------------------------------------------- #
for cmd in kubectl curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    log_error "This script requires \`$cmd\`. Please install it."
    exit 1
  fi
done

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
MODE=${1:-test}
NAMESPACE=${NAMESPACE:-"llm-d"}
MODEL_NAME=${MODEL_NAME:-"Qwen/Qwen3-0.6B"}
RELEASE_NAME_POSTFIX=${RELEASE_NAME_POSTFIX:-"kv-events"}
GATEWAY_PORT=${GATEWAY_PORT:-8000}
BENCHMARK_PVC=${BENCHMARK_PVC:-"workload-pvc"}
BENCHMARK_IMAGE=${BENCHMARK_IMAGE:-"ghcr.io/llm-d/llm-d-benchmark:v0.5.2"}

GATEWAY_SVC="infra-${RELEASE_NAME_POSTFIX}-inference-gateway-istio"
EPP_LABEL="inferencepool=gaie-${RELEASE_NAME_POSTFIX}-epp"

# --------------------------------------------------------------------------- #
# Shared long text for prefix-cache testing (≈200 words)
# --------------------------------------------------------------------------- #
LONG_TEXT="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
PF_PID=""
cleanup() {
  if [[ -n "${PF_PID}" ]] && kill -0 "${PF_PID}" 2>/dev/null; then
    kill "${PF_PID}" 2>/dev/null || true
    wait "${PF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

start_port_forward() {
  log_info "Port-forwarding ${GATEWAY_SVC} → localhost:${GATEWAY_PORT}..."
  kubectl port-forward -n "${NAMESPACE}" "svc/${GATEWAY_SVC}" "${GATEWAY_PORT}:80" &>/dev/null &
  PF_PID=$!
  # Wait for the port to become available
  local retries=0
  while ! curl -s -o /dev/null -w '' "http://localhost:${GATEWAY_PORT}" 2>/dev/null; do
    sleep 1
    retries=$((retries + 1))
    if [[ ${retries} -ge 30 ]]; then
      log_error "Port-forward did not become ready within 30 seconds."
      exit 1
    fi
  done
  log_success "Port-forward ready on localhost:${GATEWAY_PORT}."
}

send_completion() {
  local label=$1
  log_info "Sending completion request (${label})..."
  curl -s -X POST "http://localhost:${GATEWAY_PORT}/v1/completions" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${MODEL_NAME}\",
      \"prompt\": \"${LONG_TEXT}\",
      \"max_tokens\": 50
    }" | jq .
}

check_scores() {
  log_info "Checking scheduler logs for precise-prefix-cache-scorer scores..."
  echo "---"
  kubectl logs -l "${EPP_LABEL}" --all-containers=true -n "${NAMESPACE}" --tail 200 \
    | grep "Calculated score" \
    | grep "precise-prefix-cache-scorer/precise-prefix-cache-scorer" \
    | tail -20 \
    | jq -r '"  endpoint=\(.endpoint.name)  score=\(.score)"' 2>/dev/null \
    || kubectl logs -l "${EPP_LABEL}" --all-containers=true -n "${NAMESPACE}" --tail 200 \
         | grep "Calculated score" \
         | grep "precise-prefix-cache-scorer" \
         | tail -20
  echo "---"
}

# --------------------------------------------------------------------------- #
# test — quick manual verification
# --------------------------------------------------------------------------- #
do_test() {
  log_info "=== Quick Prefix-Cache Verification ==="
  log_info "Namespace: ${NAMESPACE}  Model: ${MODEL_NAME}  Gateway: ${GATEWAY_SVC}"
  echo ""

  start_port_forward

  log_info "--- Request 1: initial (expect all scores = 0) ---"
  send_completion "first"
  sleep 2
  check_scores

  log_info "--- Request 2: identical prefix (expect at least one score > 0) ---"
  send_completion "second"
  sleep 2
  check_scores

  log_success "=== Verification complete ==="
  log_info "If the second set of scores contains a non-zero value, the"
  log_info "precise prefix cache scorer is working correctly."
}

# --------------------------------------------------------------------------- #
# benchmark — full inference-perf benchmark
# --------------------------------------------------------------------------- #
do_benchmark() {
  log_info "=== Full Benchmark (inference-perf shared_prefix_synthetic) ==="
  log_info "Namespace: ${NAMESPACE}  Model: ${MODEL_NAME}  PVC: ${BENCHMARK_PVC}"
  echo ""

  local work_dir
  work_dir=$(mktemp -d)
  trap 'cleanup; rm -rf "'"${work_dir}"'"' EXIT

  cd "${work_dir}"

  # Download the benchmark runner
  log_info "Downloading run_only.sh..."
  curl -fsSL -O https://raw.githubusercontent.com/llm-d/llm-d-benchmark/main/existing_stack/run_only.sh
  chmod u+x run_only.sh

  # Download the guide.yaml benchmark template
  log_info "Downloading guide.yaml benchmark template..."
  curl -fsSL -O https://raw.githubusercontent.com/llm-d/llm-d/main/guides/precise-prefix-cache-aware/benchmark-templates/guide.yaml

  # Patch the template for our model (default template targets Qwen3-32B)
  sed -i \
    -e "s|Qwen/Qwen3-32B|${MODEL_NAME}|g" \
    -e "s|precise-guide-Qwen3-32B|precise-guide-${MODEL_NAME##*/}|g" \
    guide.yaml

  # Substitute env vars into the config
  export NAMESPACE BENCHMARK_PVC GATEWAY_SVC
  envsubst < guide.yaml > config.yaml

  log_info "Generated config.yaml:"
  head -5 config.yaml
  echo "..."
  echo ""

  # Run the benchmark
  log_info "Launching benchmark..."
  ./run_only.sh -c config.yaml

  log_success "=== Benchmark complete ==="
  log_info "Results are stored on PVC '${BENCHMARK_PVC}' in namespace '${NAMESPACE}'."
  log_info "Access via:  kubectl exec -it -n ${NAMESPACE} llmdbench-harness-launcher -- ls /workspace/requests/"
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
case "${MODE}" in
  test)
    do_test
    ;;
  benchmark)
    do_benchmark
    ;;
  *)
    log_error "Unknown mode: '${MODE}'"
    echo "Usage: $0 [test|benchmark]"
    echo ""
    echo "  test       Quick verification — sends two requests and checks prefix-cache scores"
    echo "  benchmark  Full inference-perf benchmark using the guide.yaml template"
    exit 1
    ;;
esac