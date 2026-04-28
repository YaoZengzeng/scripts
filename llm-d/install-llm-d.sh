#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Deploy the llm-d inference stack with Istio as the gateway provider.
# Deploys Qwen/Qwen3-0.6B with 1 replica, 1 GPU (resource-constrained friendly).
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
#   LLM_D_VERSION          (default: main)  git branch/tag of llm-d/llm-d repo
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
REQUIRED_CMDS=(kubectl helm git)
if [[ "${ENABLE_PRECISE_PREFIX:-false}" == "true" ]]; then
  REQUIRED_CMDS+=(helmfile)
fi
for cmd in "${REQUIRED_CMDS[@]}"; do
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
LLM_D_VERSION=${LLM_D_VERSION:-"main"}
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
  DEPLOY_METHOD="helmfile"  # precise-prefix still uses helmfile
else
  GUIDE_SUBDIR="optimized-baseline"
  DEFAULT_RN_POSTFIX="optimized-baseline"
  GUIDE_LABEL="optimized-baseline"
  DEPLOY_METHOD="helm-kustomize"  # optimized-baseline uses helm + kustomize
fi
RELEASE_NAME_POSTFIX=${RELEASE_NAME_POSTFIX:-"${DEFAULT_RN_POSTFIX}"}
GAIE_VERSION=${GAIE_VERSION:-"v1.4.0"}

# Model override: Qwen3-0.6B instead of the guide default Qwen3-32B
MODEL_NAME="Qwen/Qwen3-0.6B"
MODEL_URI="hf://Qwen/Qwen3-0.6B"
MODEL_SHORT="Qwen3-0.6B"
MODEL_SIZE="5Gi"          # 0.6B weights are ~1.2 GB; 5 Gi is generous
DECODE_REPLICAS=3
DECODE_TENSOR_PARALLEL=1  # single GPU is sufficient for a 0.6B model
DECODE_CPU="2"
DECODE_MEMORY="4Gi"
# Use the official vLLM image rather than the llm-d custom build.
# Override with VLLM_IMAGE env var if needed.
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

# Patch values files in-place: small model, single replica, monitoring disabled.
# Uses sed so no external Python/YAML library is required.
patch_values_helmfile() {
  local ms_values="${1}"
  local gaie_values="${2}"
  local infra_config="${3}"
  log_info "Patching helmfile values: model=${MODEL_NAME}, replicas=${DECODE_REPLICAS}, tensor=${DECODE_TENSOR_PARALLEL}..."

  # Replace llm-d custom CUDA image.
  sed -i \
    -e "s|image: ghcr.io/llm-d/llm-d-cuda:[^ ]*|image: ${VLLM_IMAGE}|g" \
    "${ms_values}"

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

# Patch optimized-baseline kustomize + scheduler values for small model.
patch_values_kustomize() {
  local guide_dir="${1}"
  local patch_file="${guide_dir}/modelserver/gpu/vllm/patch-vllm.yaml"
  local kustomization="${guide_dir}/modelserver/gpu/vllm/kustomization.yaml"
  log_info "Patching kustomize values: model=${MODEL_NAME}, replicas=${DECODE_REPLICAS}, tensor=${DECODE_TENSOR_PARALLEL}..."

  # Patch the kustomize Deployment overlay (patch-vllm.yaml)
  # Remove args unsupported by the target vLLM image
  sed -i \
    -e '/--disable-access-log-for-endpoints/d' \
    "${patch_file}"
  # Add --disable-log-requests to suppress noisy /metrics and /health access logs
  sed -i \
    -e '/--tensor-parallel-size/a\            - "--disable-log-requests"' \
    "${patch_file}"
  sed -i \
    -e "s|\"Qwen/Qwen3-32B\"|\"${MODEL_NAME}\"|g" \
    -e "s|Qwen/Qwen3-32B|${MODEL_NAME}|g" \
    -e "s|--tensor-parallel-size=2|--tensor-parallel-size=${DECODE_TENSOR_PARALLEL}|g" \
    -e "s|replicas: 8|replicas: ${DECODE_REPLICAS}|g" \
    -e "s|cpu: '16'|cpu: '${DECODE_CPU}'|g" \
    -e "s|cpu: '8'|cpu: '${DECODE_CPU}'|g" \
    -e "s|memory: 128Gi|memory: ${DECODE_MEMORY}|g" \
    -e "s|memory: 96Gi|memory: ${DECODE_MEMORY}|g" \
    -e "s|nvidia.com/gpu: 2|nvidia.com/gpu: 1|g" \
    "${patch_file}"

  # Patch kustomization labels
  sed -i \
    -e "s|Qwen3-32B|${MODEL_SHORT}|g" \
    "${kustomization}"

  # Override the vLLM image in kustomization.yaml
  sed -i \
    -e "s|newName: vllm/vllm-openai|newName: ${VLLM_IMAGE%:*}|g" \
    -e "s|newTag: v0\.19\.1|newTag: ${VLLM_IMAGE##*:}|g" \
    "${kustomization}"

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

  if [[ "${DEPLOY_METHOD}" == "helmfile" ]]; then
    # --- Helmfile path (precise-prefix-cache-aware) ---
    patch_values_helmfile \
      "${guide_dir}/${MS_VALUES_DIR}/values.yaml" \
      "${guide_dir}/${GAIE_VALUES_DIR}/values.yaml" \
      "${WORK_DIR}/llm-d/guides/prereq/gateway-provider/common-configurations/istio.yaml"

    log_info "Deploying llm-d ${GUIDE_LABEL} stack via helmfile (env: ${GATEWAY_ENV}, ns: ${NAMESPACE})..."
    (
      cd "${guide_dir}"
      RELEASE_NAME_POSTFIX="${RELEASE_NAME_POSTFIX}" helmfile apply -e "${GATEWAY_ENV}" -n "${NAMESPACE}"
    )
    log_success "llm-d stack deployed."

    log_info "Applying HTTPRoute for Istio..."
    kubectl apply -f "${guide_dir}/httproute.yaml" -n "${NAMESPACE}"
    log_success "HTTPRoute applied."
  else
    # --- Helm + Kustomize path (optimized-baseline) ---
    patch_values_kustomize "${guide_dir}"

    # 1. Deploy the inference scheduler (InferencePool + EPP) via helm
    local base_values="${WORK_DIR}/llm-d/guides/recipes/scheduler/base.values.yaml"
    local guide_values="${guide_dir}/scheduler/${GUIDE_SUBDIR}.values.yaml"
    log_info "Deploying inference scheduler via helm (ns: ${NAMESPACE})..."
    helm install "${RELEASE_NAME_POSTFIX}" \
      oci://registry.k8s.io/gateway-api-inference-extension/charts/standalone \
      -f "${base_values}" \
      -f "${guide_values}" \
      -n "${NAMESPACE}" --version "${GAIE_VERSION}"
    log_success "Inference scheduler deployed."

    # Expose the EPP service as LoadBalancer for external access
    kubectl patch svc "${RELEASE_NAME_POSTFIX}-epp" -n "${NAMESPACE}" \
      -p '{"spec":{"type":"LoadBalancer"}}'
    log_success "EPP service patched to LoadBalancer."

    # 2. Deploy the model server via kustomize
    log_info "Deploying model server via kustomize (ns: ${NAMESPACE})..."
    kubectl apply -n "${NAMESPACE}" -k "${guide_dir}/modelserver/gpu/vllm/"
    log_success "Model server deployed."
  fi

  verify
}

uninstall() {
  clone_repo
  local guide_dir="${WORK_DIR}/llm-d/guides/${GUIDE_SUBDIR}"

  if [[ "${DEPLOY_METHOD}" == "helmfile" ]]; then
    log_info "Removing HTTPRoute..."
    kubectl delete -f "${guide_dir}/httproute.yaml" -n "${NAMESPACE}" --ignore-not-found || true

    log_info "Destroying llm-d ${GUIDE_LABEL} stack via helmfile..."
    (
      cd "${guide_dir}"
      RELEASE_NAME_POSTFIX="${RELEASE_NAME_POSTFIX}" helmfile destroy -n "${NAMESPACE}"
    ) || {
      log_info "helmfile destroy failed; falling back to manual helm uninstall..."
      helm uninstall "infra-${RELEASE_NAME_POSTFIX}" -n "${NAMESPACE}" --ignore-not-found || true
      helm uninstall "gaie-${RELEASE_NAME_POSTFIX}"  -n "${NAMESPACE}" --ignore-not-found || true
      helm uninstall "ms-${RELEASE_NAME_POSTFIX}"    -n "${NAMESPACE}" --ignore-not-found || true
    }
  else
    log_info "Removing model server (kustomize)..."
    kubectl delete -n "${NAMESPACE}" -k "${guide_dir}/modelserver/gpu/vllm/" --ignore-not-found || true

    log_info "Removing inference scheduler (helm)..."
    helm uninstall "${RELEASE_NAME_POSTFIX}" -n "${NAMESPACE}" --ignore-not-found || true
  fi

  log_success "llm-d ${GUIDE_LABEL} stack removed."
}

verify() {
  log_info "Current resources in namespace '${NAMESPACE}':"
  kubectl get all -n "${NAMESPACE}" 2>/dev/null || true

  log_info ""
  log_info "To test once all pods are Running:"
  if [[ "${DEPLOY_METHOD}" == "helmfile" ]]; then
    local gw_svc="infra-${RELEASE_NAME_POSTFIX}-inference-gateway-istio"
    log_info "  # Terminal 1 — port-forward the Istio gateway service:"
    log_info "  kubectl port-forward -n ${NAMESPACE} svc/${gw_svc} 8080:80"
  else
    local epp_svc="${RELEASE_NAME_POSTFIX}-epp"
    log_info "  # Get the external IP of the EPP service:"
    log_info "  export IP=\$(kubectl get svc ${epp_svc} -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
    log_info "  # Then send requests to http://\$IP:9001"
  fi
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
