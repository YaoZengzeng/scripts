#!/bin/bash
# Initialize the full stack: GPU operator, Volcano, Kthena, observability, Redis,
# and the llm-d inference stack with ModelServer/ModelRoute.
#
# Usage:
#   HF_TOKEN=<your-token> bash init.sh
#
# Environment variables:
#   HF_TOKEN   (required) HuggingFace token for model downloads
#   NAMESPACE  (default: llm-d) namespace for the llm-d stack

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LLM_D_DIR="$ROOT_DIR/llm-d"
NAMESPACE=${NAMESPACE:-"llm-d"}

# --------------------------------------------------------------------------- #
# Validate required environment variables
# --------------------------------------------------------------------------- #
if [[ -z "${HF_TOKEN:-}" ]]; then
  echo "❌ HF_TOKEN environment variable is required."
  echo "Usage: HF_TOKEN=<your-token> bash $0"
  exit 1
fi

# --------------------------------------------------------------------------- #
# Phase 1: Infrastructure (GPU, Volcano, Kthena, Observability, Redis)
# --------------------------------------------------------------------------- #
echo "==> Installing NVIDIA GPU Operator..."
bash "$SCRIPT_DIR/install_k8s_gpu_operator.sh"

echo "==> Installing Volcano scheduler..."
bash "$ROOT_DIR/kthena/install_volcano.sh"

echo "==> Installing Kthena chart..."
bash "$ROOT_DIR/kthena/install_chart.sh"

echo "==> Installing observability stack..."
STANDALONE=1 bash "$ROOT_DIR/vllm/observability/install.sh"

echo "==> Deploying Redis standalone..."
kubectl apply -f "$ROOT_DIR/vllm/kthena/redis-standalone.yaml"

# --------------------------------------------------------------------------- #
# Phase 2: llm-d inference stack
# --------------------------------------------------------------------------- #
echo "==> Creating HuggingFace token secret..."
HF_TOKEN="${HF_TOKEN}" NAMESPACE="${NAMESPACE}" bash "$LLM_D_DIR/llm-d-hf-token.sh"

echo "==> Installing Gateway control plane (Istio + CRDs)..."
bash "$LLM_D_DIR/install-gateway-control-plane.sh" install

echo "==> Deploying llm-d inference stack..."
NAMESPACE="${NAMESPACE}" bash "$LLM_D_DIR/install-llm-d.sh" install

# --------------------------------------------------------------------------- #
# Phase 3: Volcano ModelServer & ModelRoute
# --------------------------------------------------------------------------- #
echo "==> Applying ModelServer..."
kubectl apply -f "$LLM_D_DIR/modelserver.yaml"

echo "==> Applying ModelRoute..."
kubectl apply -f "$LLM_D_DIR/modelroute.yaml"

echo "==> Initialization complete."
