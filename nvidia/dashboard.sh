#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Install / Uninstall NVIDIA GPU Usage Monitor dashboard on Kubernetes.
# Deploys Prometheus, Grafana and (optionally) kube-state-metrics via the
# upstream Helm chart at https://github.com/NVIDIA/gpu-usage-monitor
#
# Usage:
#   ./dashboard.sh [install|uninstall|status]
#
# Environment variables:
#   NAMESPACE             (default: gpu-usage-monitor)
#   RELEASE_NAME          (default: gpu-usage-monitor)
#   GRAFANA_USER          (default: admin)
#   GRAFANA_PASSWORD      (default: admin)
#   ENABLE_KSM            (default: false)  enable kube-state-metrics
#   EXTERNAL_PROMETHEUS   (default: "")     URL of an existing Prometheus server
#   CHART_VERSION         (default: "")     pin a specific chart version

set -euo pipefail

# --------------------------------------------------------------------------- #
# Defaults
# --------------------------------------------------------------------------- #
NAMESPACE="${NAMESPACE:-gpu-usage-monitor}"
RELEASE_NAME="${RELEASE_NAME:-gpu-usage-monitor}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"
ENABLE_KSM="${ENABLE_KSM:-false}"
EXTERNAL_PROMETHEUS="${EXTERNAL_PROMETHEUS:-}"
CHART_VERSION="${CHART_VERSION:-}"

REPO_URL="https://github.com/NVIDIA/gpu-usage-monitor.git"
CHART_DIR=""          # populated after clone
TMPDIR_ROOT=""        # populated after mktemp

# --------------------------------------------------------------------------- #
# Colour helpers
# --------------------------------------------------------------------------- #
COLOR_RESET=$'\e[0m'
COLOR_GREEN=$'\e[32m'
COLOR_RED=$'\e[31m'
COLOR_YELLOW=$'\e[33m'

log_ok()   { echo "${COLOR_GREEN}✅ $*${COLOR_RESET}"; }
log_err()  { echo "${COLOR_RED}❌ $*${COLOR_RESET}" >&2; }
log_info() { echo "ℹ️  $*"; }
log_warn() { echo "${COLOR_YELLOW}⚠️  $*${COLOR_RESET}"; }

# --------------------------------------------------------------------------- #
# Pre-flight checks
# --------------------------------------------------------------------------- #
preflight() {
  local missing=()
  command -v kubectl >/dev/null 2>&1 || missing+=(kubectl)
  command -v helm    >/dev/null 2>&1 || missing+=(helm)
  command -v git     >/dev/null 2>&1 || missing+=(git)

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_err "Missing required tools: ${missing[*]}"
    exit 1
  fi

  if ! kubectl cluster-info >/dev/null 2>&1; then
    log_err "Cannot reach a Kubernetes cluster. Check your kubeconfig."
    exit 1
  fi

  log_ok "Pre-flight checks passed (kubectl, helm, git, cluster reachable)"
}

# --------------------------------------------------------------------------- #
# Clone chart & update dependencies
# --------------------------------------------------------------------------- #
prepare_chart() {
  TMPDIR_ROOT=$(mktemp -d)
  trap 'rm -rf "${TMPDIR_ROOT}"' EXIT

  log_info "Cloning gpu-usage-monitor chart …"
  git clone --depth 1 "${REPO_URL}" "${TMPDIR_ROOT}/gpu-usage-monitor" >/dev/null 2>&1
  CHART_DIR="${TMPDIR_ROOT}/gpu-usage-monitor"

  log_info "Updating Helm dependencies …"
  helm dependency update "${CHART_DIR}" >/dev/null 2>&1
  log_ok "Chart dependencies downloaded"
}

# --------------------------------------------------------------------------- #
# Build Helm value overrides
# --------------------------------------------------------------------------- #
build_values() {
  local values_args=()

  # Grafana credentials
  values_args+=(--set "grafana.adminUser=${GRAFANA_USER}")
  values_args+=(--set "grafana.adminPassword=${GRAFANA_PASSWORD}")

  # kube-state-metrics
  values_args+=(--set "prometheus.kube-state-metrics.enabled=${ENABLE_KSM}")

  # Grafana service type LoadBalancer
  values_args+=(--set "grafana.service.type=LoadBalancer")

  # External Prometheus
  if [[ -n "${EXTERNAL_PROMETHEUS}" ]]; then
    values_args+=(--set "prometheus.enabled=false")
    values_args+=(--set "global.prometheusUrl=${EXTERNAL_PROMETHEUS}")
  fi

  echo "${values_args[@]}"
}

# --------------------------------------------------------------------------- #
# Install
# --------------------------------------------------------------------------- #
do_install() {
  preflight
  prepare_chart

  log_info "Installing ${RELEASE_NAME} into namespace ${NAMESPACE} …"

  local -a values_args
  read -ra values_args <<< "$(build_values)"

  local -a version_arg=()
  if [[ -n "${CHART_VERSION}" ]]; then
    version_arg+=(--version "${CHART_VERSION}")
  fi

  helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    "${version_arg[@]}" \
    "${values_args[@]}" \
    --wait --timeout 5m

  log_ok "GPU Usage Monitor installed successfully"
  echo ""
  log_info "Components deployed:"
  log_info "  • Prometheus  (metrics collection)"
  if [[ "${ENABLE_KSM}" == "true" ]]; then
    log_info "  • kube-state-metrics  (Kubernetes resource metrics)"
  fi
  log_info "  • Grafana     (dashboard visualisation)"
  echo ""
  log_info "Access the dashboard:"
  log_info "  kubectl get svc -n ${NAMESPACE} ${RELEASE_NAME}-grafana  (check EXTERNAL-IP)"
  log_info "  Username: ${GRAFANA_USER}  Password: ${GRAFANA_PASSWORD}"

  # Verify DCGM exporter presence
  echo ""
  if kubectl get pods -A 2>/dev/null | grep -q dcgm; then
    log_ok "DCGM Exporter pods detected in the cluster"
  else
    log_warn "No DCGM Exporter pods found. GPU metrics require DCGM Exporter"
    log_warn "Deploy it via the NVIDIA GPU Operator or standalone dcgm-exporter chart"
  fi
}

# --------------------------------------------------------------------------- #
# Uninstall
# --------------------------------------------------------------------------- #
do_uninstall() {
  log_info "Uninstalling ${RELEASE_NAME} from namespace ${NAMESPACE} …"
  helm uninstall "${RELEASE_NAME}" --namespace "${NAMESPACE}" 2>/dev/null \
    && log_ok "Release ${RELEASE_NAME} removed" \
    || log_warn "Release ${RELEASE_NAME} not found"

  read -rp "Delete namespace ${NAMESPACE}? [y/N] " answer
  if [[ "${answer}" =~ ^[Yy]$ ]]; then
    kubectl delete namespace "${NAMESPACE}" --ignore-not-found
    log_ok "Namespace ${NAMESPACE} deleted"
  fi
}

# --------------------------------------------------------------------------- #
# Status
# --------------------------------------------------------------------------- #
do_status() {
  log_info "Helm release:"
  helm status "${RELEASE_NAME}" --namespace "${NAMESPACE}" 2>/dev/null \
    || log_warn "Release ${RELEASE_NAME} not found in namespace ${NAMESPACE}"

  echo ""
  log_info "Pods in namespace ${NAMESPACE}:"
  kubectl get pods -n "${NAMESPACE}" 2>/dev/null \
    || log_warn "Namespace ${NAMESPACE} does not exist"

  echo ""
  log_info "DCGM Exporter pods (cluster-wide):"
  kubectl get pods -A 2>/dev/null | grep dcgm || log_warn "No DCGM Exporter pods found"
}


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
ACTION="${1:-install}"

case "${ACTION}" in
  install)       do_install ;;
  uninstall)     do_uninstall ;;
  status)        do_status ;;
  *)
    echo "Usage: $0 [install|uninstall|status]"
    exit 1
    ;;
esac
