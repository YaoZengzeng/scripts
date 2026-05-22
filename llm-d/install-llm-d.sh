#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Deploy the llm-d inference stack with Istio as the gateway provider.
# Deploys Qwen/Qwen3-0.6B with 3 replicas, 1 GPU each (resource-constrained friendly).
#
# Pinned to llm-d v0.5.1 for stability.
#
# Usage:
#   ./install-llm-d.sh [install|uninstall|verify]
#
# Prerequisites:
#   - Gateway control plane installed (run install-gateway-control-plane.sh first)
#   - HuggingFace token secret created in the target namespace:
#       kubectl create secret generic llm-d-hf-token \
#         --from-literal=HF_TOKEN=<your-token> -n <namespace>
#
# Note: The monitoring stack (Prometheus/PodMonitor) is intentionally disabled.
#
# Environment variables:
#   NAMESPACE              (default: llm-d)
#   LLM_D_VERSION          (default: v0.5.1)  git branch/tag of llm-d/llm-d repo
#   RELEASE_NAME_POSTFIX   (default: depends on guide)
#   ENABLE_PRECISE_PREFIX  (default: false)  set "true" to deploy the
#                          precise-prefix-cache-aware guide with KV-events
#                          based routing instead of approximate routing.

set +x
set -e
set -o pipefail

# --------------------------------------------------------------------------- #
# Colour helpers
# --------------------------------------------------------------------------- #
COLOR_RESET=$'\e[0m'
COLOR_GREEN=$'\e[32m'
COLOR_RED=$'\e[31m'

log_success() { echo "${COLOR_GREEN}✅ $*${COLOR_RESET}"; }
log_error()   { echo "${COLOR_RED}❌ $*${COLOR_RESET}" >&2; }
log_info()    { echo "ℹ️  $*"; }

# --------------------------------------------------------------------------- #
# Pre-flight checks
# --------------------------------------------------------------------------- #
for cmd in kubectl helm helmfile git; do
  if ! command -v "$cmd" &>/dev/null; then
    log_error "This script depends on \`$cmd\`. Please install it."
    exit 1
  fi
done

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
MODE=${1:-install}
NAMESPACE=${NAMESPACE:-"llm-d"}
LLM_D_VERSION=${LLM_D_VERSION:-"v0.5.1"}
LLM_D_REPO="https://github.com/llm-d/llm-d.git"
ENABLE_PRECISE_PREFIX=${ENABLE_PRECISE_PREFIX:-"false"}
GATEWAY_ENV="istio"

# Select the guide based on ENABLE_PRECISE_PREFIX
if [[ "${ENABLE_PRECISE_PREFIX}" == "true" ]]; then
  GUIDE_SUBDIR="precise-prefix-cache-aware"
  DEFAULT_RN_POSTFIX="kv-events"
  MS_VALUES_DIR="ms-kv-events"
  GAIE_VALUES_DIR="gaie-kv-events"
  GUIDE_LABEL="precise-prefix-cache-aware"
else
  GUIDE_SUBDIR="inference-scheduling"
  DEFAULT_RN_POSTFIX="inference-scheduling"
  MS_VALUES_DIR="ms-inference-scheduling"
  GAIE_VALUES_DIR="gaie-inference-scheduling"
  GUIDE_LABEL="inference-scheduling"
fi
RELEASE_NAME_POSTFIX=${RELEASE_NAME_POSTFIX:-"${DEFAULT_RN_POSTFIX}"}

# Model override: Qwen3-0.6B instead of the guide default Qwen3-32B
MODEL_NAME="Qwen/Qwen3-0.6B"
MODEL_URI="hf://Qwen/Qwen3-0.6B"
MODEL_SHORT="Qwen3-0.6B"
MODEL_SIZE="5Gi"          # 0.6B weights are ~1.2 GB; 5 Gi is generous
DECODE_REPLICAS=3
DECODE_TENSOR_PARALLEL=1  # single GPU is sufficient for a 0.6B model
DECODE_CPU="2"
DECODE_MEMORY="4Gi"
VLLM_IMAGE=${VLLM_IMAGE:-"ghcr.io/llm-d/llm-d-cuda:v0.5.1"}

WORK_DIR=$(mktemp -d)

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

clone_repo() {
  if [[ ! -d "${WORK_DIR}/llm-d" ]]; then
    log_info "Cloning llm-d repository (${LLM_D_VERSION})..."
    local branch_args=()
    [[ -n "${LLM_D_VERSION}" ]] && branch_args=(--branch "${LLM_D_VERSION}")
    git clone --depth=1 "${branch_args[@]}" "${LLM_D_REPO}" "${WORK_DIR}/llm-d"
    log_success "Repository cloned."
  fi
}

# Patch values files in-place: small model, fewer replicas, monitoring disabled.
patch_values() {
  local ms_values="${1}"
  local gaie_values="${2}"
  local infra_config="${3}"
  log_info "Patching values: model=${MODEL_NAME}, replicas=${DECODE_REPLICAS}, tensor=${DECODE_TENSOR_PARALLEL}..."

  # Model, size, parallelism, resources
  sed -i \
    -e "s|Qwen/Qwen3-32B|${MODEL_NAME}|g" \
    -e "s|Qwen3-32B|${MODEL_SHORT}|g" \
    -e "s|size: 80Gi|size: ${MODEL_SIZE}|g" \
    -e "s|tensor: 2|tensor: ${DECODE_TENSOR_PARALLEL}|g" \
    -e "s|replicas: 8|replicas: ${DECODE_REPLICAS}|g" \
    -e "s|cpu: '32'|cpu: '${DECODE_CPU}'|g" \
    -e "s|memory: 100Gi|memory: ${DECODE_MEMORY}|g" \
    "${ms_values}"

  # Patch model name inside the GAIE pluginsCustomConfig (precise-prefix guide
  # embeds model names in the scorer / tokenizer plugin YAML).
  sed -i \
    -e "s|modelName: Qwen/Qwen3-32B|modelName: ${MODEL_NAME}|g" \
    -e "s|Qwen/Qwen3-32B|${MODEL_NAME}|g" \
    "${gaie_values}"

  # Disable PodMonitor (requires Prometheus operator) in ms values
  sed -i \
    -e '/podmonitor:/,/enabled:/ s|enabled: true|enabled: false|' \
    "${ms_values}"

  # Disable Prometheus monitoring in gaie (InferencePool/EPP) values
  sed -i \
    -e '/prometheus:/,/enabled:/ s|enabled: true|enabled: false|' \
    "${gaie_values}"

  # Set gateway service type to LoadBalancer in the Istio infra common config
  sed -i \
    -e 's|^gateway:|gateway:\n  service:\n    type: LoadBalancer|' \
    "${infra_config}"

  log_success "Values patched."
}

install() {
  # --- Namespace ---
  log_info "Creating namespace '${NAMESPACE}'..."
  kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

  # --- Verify HF token secret exists ---
  if ! kubectl get secret llm-d-hf-token -n "${NAMESPACE}" &>/dev/null; then
    log_error "HuggingFace token secret 'llm-d-hf-token' not found in namespace '${NAMESPACE}'."
    log_error "Create it first, then re-run this script:"
    log_error "  export HF_TOKEN=<your-huggingface-token>"
    log_error "  kubectl create secret generic llm-d-hf-token --from-literal=HF_TOKEN=\${HF_TOKEN} -n ${NAMESPACE}"
    exit 1
  fi

  # --- Clone llm-d repo ---
  clone_repo
  local guide_dir="${WORK_DIR}/llm-d/guides/${GUIDE_SUBDIR}"

  # --- Patch values for small model + fewer replicas, monitoring disabled ---
  patch_values \
    "${guide_dir}/${MS_VALUES_DIR}/values.yaml" \
    "${guide_dir}/${GAIE_VALUES_DIR}/values.yaml" \
    "${WORK_DIR}/llm-d/guides/prereq/gateway-provider/common-configurations/istio.yaml"

  # --- Deploy the three Helm releases via helmfile ---
  #   infra-<postfix>  — Gateway / InferenceGateway
  #   gaie-<postfix>   — InferencePool + inference-scheduler (EPP)
  #   ms-<postfix>     — ModelService (vLLM decode pods)
  log_info "Deploying llm-d ${GUIDE_LABEL} stack (env: ${GATEWAY_ENV}, ns: ${NAMESPACE})..."
  (
    cd "${guide_dir}"
    RELEASE_NAME_POSTFIX="${RELEASE_NAME_POSTFIX}" helmfile apply -e "${GATEWAY_ENV}" -n "${NAMESPACE}"
  )
  log_success "llm-d stack deployed."

  # --- Label vLLM decode pods with volcano modelserving identifier ---
  log_info "Patching decode deployment to add modelserving.volcano.sh/name label..."
  local decode_deploy
  decode_deploy=$(kubectl get deploy -n "${NAMESPACE}" -l llm-d.ai/role=decode -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -n "${decode_deploy}" ]]; then
    kubectl patch deployment "${decode_deploy}" -n "${NAMESPACE}" \
      --type=json \
      -p='[{"op":"add","path":"/spec/template/metadata/labels/modelserving.volcano.sh~1name","value":"vllm-qwen-06b"}]'
    log_success "Label 'modelserving.volcano.sh/name: vllm-qwen-06b' added to pod template."
  else
    log_error "Could not find decode deployment to patch. Adding label via kubectl label on existing pods..."
    kubectl label pods -n "${NAMESPACE}" -l llm-d.ai/role=decode \
      "modelserving.volcano.sh/name=vllm-qwen-06b" --overwrite
  fi

  # --- HTTPRoute: routes Gateway traffic → InferencePool ---
  log_info "Applying HTTPRoute for Istio..."
  kubectl apply -f "${guide_dir}/httproute.yaml" -n "${NAMESPACE}"
  log_success "HTTPRoute applied."

  verify
}

uninstall() {
  clone_repo
  local guide_dir="${WORK_DIR}/llm-d/guides/${GUIDE_SUBDIR}"

  log_info "Removing HTTPRoute..."
  kubectl delete -f "${guide_dir}/httproute.yaml" -n "${NAMESPACE}" --ignore-not-found || true

  log_info "Destroying llm-d ${GUIDE_LABEL} stack..."
  (
    cd "${guide_dir}"
    RELEASE_NAME_POSTFIX="${RELEASE_NAME_POSTFIX}" helmfile destroy -n "${NAMESPACE}"
  ) || {
    log_info "helmfile destroy failed; falling back to manual helm uninstall..."
    helm uninstall "infra-${RELEASE_NAME_POSTFIX}" -n "${NAMESPACE}" --ignore-not-found || true
    helm uninstall "gaie-${RELEASE_NAME_POSTFIX}"  -n "${NAMESPACE}" --ignore-not-found || true
    helm uninstall "ms-${RELEASE_NAME_POSTFIX}"    -n "${NAMESPACE}" --ignore-not-found || true
  }

  log_success "llm-d ${GUIDE_LABEL} stack removed."
}

verify() {
  log_info "Current resources in namespace '${NAMESPACE}':"
  kubectl get all -n "${NAMESPACE}" 2>/dev/null || true

  local gw_svc="infra-${RELEASE_NAME_POSTFIX}-inference-gateway-istio"
  log_info ""
  log_info "To test once all pods are Running:"
  log_info "  # Terminal 1 — port-forward the Istio gateway service:"
  log_info "  kubectl port-forward -n ${NAMESPACE} svc/${gw_svc} 8080:80"
  log_info ""
  log_info "  # Terminal 2 — send a chat completion request:"
  log_info "  curl -X POST http://localhost:8080/v1/chat/completions \\"
  log_info "    -H 'Content-Type: application/json' \\"
  log_info "    -d '{\"model\": \"${MODEL_NAME}\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}], \"max_tokens\": 50}'"
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
case "${MODE}" in
  install)
    log_info "=== Deploying llm-d ${GUIDE_LABEL} (model: ${MODEL_NAME}, replicas: ${DECODE_REPLICAS}) ==="
    install
    log_success "=== Deployment complete ==="
    ;;
  uninstall)
    log_info "=== Removing llm-d ${GUIDE_LABEL} ==="
    uninstall
    log_success "=== Removal complete ==="
    ;;
  verify)
    verify
    ;;
  *)
    log_error "Unknown mode: '${MODE}'. Usage: $0 [install|uninstall|verify]"
    exit 1
    ;;
esac
