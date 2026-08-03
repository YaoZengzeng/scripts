#!/usr/bin/env bash
# install-kuberay.sh -- one-shot install of the KubeRay operator + CRDs.
#
# Installs the CRDs (cluster-scoped, needs admin) and the KubeRay operator
# (namespace-scoped, watching a single namespace) at the version the llm-d-rl
# verl demo expects. After this, /root/scripts/rl/run-demo.sh can deploy the
# RayCluster into the same namespace.
#
# Usage:
#   bash install-kuberay.sh              # install CRDs + operator (v1.5.1)
#   bash install-kuberay.sh uninstall    # remove the operator (leaves CRDs)
#
# Env overrides (optional):
#   NAMESPACE       operator namespace   (default: llm-d-rl-demo -- matches run-demo.sh)
#   KUBERAY_VERSION chart/CRD version    (default: 1.5.1)
#   SKIP_CRDS=1     do not install CRDs  (use if a cluster-admin already added them)
set -euo pipefail

ACTION="${1:-install}"
NAMESPACE="${NAMESPACE:-llm-d-rl-demo}"
KUBERAY_VERSION="${KUBERAY_VERSION:-1.5.1}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' not found on PATH"; exit 1; }; }
need kubectl
need helm

if [[ "$ACTION" == "uninstall" ]]; then
  echo ">> uninstalling kuberay-operator from namespace '$NAMESPACE'"
  helm uninstall kuberay-operator --namespace "$NAMESPACE" || true
  echo ">> done (CRDs left in place; remove manually if desired: kubectl delete crd rayclusters.ray.io rayjobs.ray.io rayservices.ray.io)"
  exit 0
fi

# --- 1. CRDs (cluster-scoped) ------------------------------------------------
if [[ "${SKIP_CRDS:-0}" != "1" ]]; then
  if kubectl get crd rayclusters.ray.io >/dev/null 2>&1; then
    echo ">> Ray CRDs already present, skipping CRD install"
  else
    echo ">> installing Ray CRDs (v${KUBERAY_VERSION}, needs cluster-admin)"
    kubectl create -k "github.com/ray-project/kuberay/ray-operator/config/crd?ref=v${KUBERAY_VERSION}&timeout=90s"
  fi
else
  echo ">> SKIP_CRDS=1: assuming Ray CRDs already installed"
fi

# --- 2. namespace ------------------------------------------------------------
echo ">> ensuring namespace '$NAMESPACE'"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# --- 3. operator (namespace-scoped Helm release) -----------------------------
echo ">> adding/updating the KubeRay Helm repo"
helm repo add kuberay https://ray-project.github.io/kuberay-helm/ >/dev/null 2>&1 || true
helm repo update kuberay >/dev/null

echo ">> installing kuberay-operator v${KUBERAY_VERSION} into '$NAMESPACE' (single-namespace, skip-crds)"
helm upgrade --install kuberay-operator kuberay/kuberay-operator \
  --version "$KUBERAY_VERSION" \
  --namespace "$NAMESPACE" \
  --set singleNamespaceInstall=true \
  --skip-crds \
  --wait --timeout 5m

echo ">> waiting for operator deployment to be available"
kubectl rollout status deploy/kuberay-operator -n "$NAMESPACE" --timeout=180s

echo ">> KubeRay ready in namespace '$NAMESPACE'."
echo "   Next: NAMESPACE=$NAMESPACE bash /root/scripts/rl/run-demo.sh"
