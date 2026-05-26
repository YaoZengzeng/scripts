#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Install the llm-d gateway control plane using Istio as the provider.
#
# Usage:
#   ./install-gateway-control-plane.sh [install|uninstall]
#
# Environment variables:
#   GATEWAY_API_CRD_REVISION                     (default: v1.5.1)
#   GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION (default: v1.4.0)
#   ISTIO_VERSION                                (default: 1.29.1)
#   ISTIO_HUB                                    (default: docker.io/istio)

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
for cmd in kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    log_error "This script depends on \`$cmd\`. Please install it."
    exit 1
  fi
done

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
MODE=${1:-install}
GATEWAY_API_CRD_REVISION=${GATEWAY_API_CRD_REVISION:-"v1.5.1"}
GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION=${GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION:-"v1.4.0"}
ISTIO_VERSION=${ISTIO_VERSION:-"1.29.1"}
ISTIO_HUB=${ISTIO_HUB:-"docker.io/istio"}

ISTIO_NAMESPACE="istio-system"
ISTIO_REPO_NAME="istio"
ISTIO_REPO_URL="https://istio-release.storage.googleapis.com/charts"

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
install_crds() {
  log_info "Installing Gateway API CRDs (${GATEWAY_API_CRD_REVISION})..."
  kubectl apply -k \
    "https://github.com/kubernetes-sigs/gateway-api/config/crd/?ref=${GATEWAY_API_CRD_REVISION}"
  log_success "Gateway API CRDs installed."

  log_info "Installing Gateway API Inference Extension CRDs (${GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION})..."
  kubectl apply -k \
    "https://github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd/?ref=${GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION}"
  log_success "Gateway API Inference Extension CRDs installed."
}

uninstall_crds() {
  log_info "Removing Gateway API Inference Extension CRDs (${GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION})..."
  kubectl delete -k \
    "https://github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd/?ref=${GATEWAY_API_INFERENCE_EXTENSION_CRD_REVISION}" \
    --ignore-not-found || true
  log_success "Gateway API Inference Extension CRDs removed."

  log_info "Removing Gateway API CRDs (${GATEWAY_API_CRD_REVISION})..."
  kubectl delete -k \
    "https://github.com/kubernetes-sigs/gateway-api/config/crd/?ref=${GATEWAY_API_CRD_REVISION}" \
    --ignore-not-found || true
  log_success "Gateway API CRDs removed."
}

install_istio() {
  log_info "Adding Istio Helm repository..."
  helm repo add "${ISTIO_REPO_NAME}" "${ISTIO_REPO_URL}" 2>/dev/null || true
  helm repo update

  log_info "Creating namespace ${ISTIO_NAMESPACE}..."
  kubectl create namespace "${ISTIO_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

  log_info "Installing istio-base (${ISTIO_VERSION})..."
  helm upgrade --install istio-base "${ISTIO_REPO_NAME}/base" \
    --version "${ISTIO_VERSION}" \
    --namespace "${ISTIO_NAMESPACE}" \
    --wait
  log_success "istio-base installed."

  log_info "Installing istiod (${ISTIO_VERSION}) with Gateway API Inference Extension enabled..."
  helm upgrade --install istiod "${ISTIO_REPO_NAME}/istiod" \
    --version "${ISTIO_VERSION}" \
    --namespace "${ISTIO_NAMESPACE}" \
    --set "meshConfig.defaultConfig.proxyMetadata.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true" \
    --set "pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true" \
    --set "tag=${ISTIO_VERSION}" \
    --set "hub=${ISTIO_HUB}" \
    --wait
  log_success "istiod installed."
}

uninstall_istio() {
  log_info "Uninstalling istiod..."
  helm uninstall istiod --namespace "${ISTIO_NAMESPACE}" --ignore-not-found 2>/dev/null || true
  log_success "istiod uninstalled."

  log_info "Uninstalling istio-base..."
  helm uninstall istio-base --namespace "${ISTIO_NAMESPACE}" --ignore-not-found 2>/dev/null || true
  log_success "istio-base uninstalled."

  log_info "Deleting namespace ${ISTIO_NAMESPACE}..."
  kubectl delete namespace "${ISTIO_NAMESPACE}" --ignore-not-found || true
  log_success "Namespace ${ISTIO_NAMESPACE} deleted."
}

verify_installation() {
  log_info "Verifying installation — checking for InferencePool API (v1)..."
  if kubectl api-resources --api-group=inference.networking.k8s.io 2>/dev/null | grep -q "inferencepools"; then
    log_success "InferencePool API is available."
  else
    log_error "InferencePool API not found. CRDs may not have been applied correctly."
    exit 1
  fi
  log_success "Verification complete."
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
case "${MODE}" in
  install)
    log_info "=== Installing llm-d gateway control plane (Istio) ==="
    install_crds
    install_istio
    verify_installation
    log_success "=== Gateway control plane (Istio) installation complete ==="
    ;;
  uninstall)
    log_info "=== Uninstalling llm-d gateway control plane (Istio) ==="
    uninstall_istio
    uninstall_crds
    log_success "=== Gateway control plane (Istio) uninstalled ==="
    ;;
  *)
    log_error "Unknown mode: '${MODE}'. Usage: $0 [install|uninstall]"
    exit 1
    ;;
esac
