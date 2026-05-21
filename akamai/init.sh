#!/bin/bash
# Initialize the full stack: GPU operator, Volcano, Kthena, observability, and Redis.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

echo "==> Deploying vllm pods"

bash "$ROOT_DIR/vllm/kthena/install_gpu.sh"

echo "==> Initialization complete."
