#!/usr/bin/env bash
# run-demo.sh -- ONE-SHOT minimal verl + llm-d EPP demo on 2x ~20GB GPUs.
#
# Does everything: creates the namespace, deploys the 2-GPU KubeRay cluster
# (Qwen3-0.6B, GRPO on GSM8K), waits until both pods finished their postStart
# setup, then runs training routed through the llm-d Endpoint Picker (EPP).
# TP=1 over 2 GPUs => 2 vLLM replicas for EPP to route between.
#
# Assumes /root/llm-d-rl exists and your kube-context points at a cluster with
# 2 schedulable GPUs (as nvidia.com/gpu) and the KubeRay operator installed.
# No other configuration required.
#
# Usage:
#   bash run-demo.sh              # deploy (if needed) + run EPP demo
#   bash run-demo.sh native       # same, but verl's native routing (baseline)
#   bash run-demo.sh teardown     # delete the cluster
#
# Env overrides (all optional):
#   NAMESPACE   (default: llm-d-rl-demo)
#   REPO_DIR    (default: /root/llm-d-rl)
#   STEPS       training steps        (default: 3   -- keeps total run < 15 min)
#   N           GRPO rollout group    (default: 8)
#   GPU_MEM_UTIL vLLM mem fraction    (default: 0.5 -- lower to 0.4/0.3 if OOM)
#   SKIP_DEPLOY=1  skip deploy/wait, just run training on an existing cluster
set -euo pipefail

MODE="${1:-epp}"
NAMESPACE="${NAMESPACE:-llm-d-rl-demo}"
REPO_DIR="${REPO_DIR:-/root/llm-d-rl}"
STEPS="${STEPS:-3}"
N="${N:-8}"
GPU_MEM_UTIL="${GPU_MEM_UTIL:-0.5}"
export NAMESPACE

KUBERAY_DIR="$REPO_DIR/integrations/verl/deploy/kuberay"
TMPL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ray-cluster.yaml.tmpl"
START_TS=$(date +%s)
elapsed() { printf '[%dm%02ds]' $(( ($(date +%s)-START_TS)/60 )) $(( ($(date +%s)-START_TS)%60 )); }

if [[ "$MODE" == "teardown" ]]; then
  echo ">> tearing down cluster in namespace '$NAMESPACE'"
  ( cd "$KUBERAY_DIR" && bash deploy.sh delete ) || true
  exit 0
fi

# --- 1. deploy ---------------------------------------------------------------
if [[ "${SKIP_DEPLOY:-0}" != "1" ]]; then
  [[ -d "$KUBERAY_DIR" ]] || { echo "ERROR: $KUBERAY_DIR not found (set REPO_DIR)"; exit 1; }

  echo "$(elapsed) >> ensuring namespace '$NAMESPACE'"
  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  # Install the 2-GPU template into the repo (deploy.sh renders it in place).
  # Back the original up once so `teardown` / re-runs stay clean.
  if [[ ! -f "$KUBERAY_DIR/ray-cluster.yaml.tmpl.orig" ]]; then
    cp "$KUBERAY_DIR/ray-cluster.yaml.tmpl" "$KUBERAY_DIR/ray-cluster.yaml.tmpl.orig"
  fi
  cp "$TMPL_SRC" "$KUBERAY_DIR/ray-cluster.yaml.tmpl"

  echo "$(elapsed) >> deploying KubeRay cluster (ConfigMap + manifest)"
  ( cd "$KUBERAY_DIR" && bash deploy.sh apply )

  # --- 2. wait for pods Ready, then for postStart setup to finish -----------
  echo "$(elapsed) >> waiting for head + worker pods to be Ready (image pull may be slow)"
  kubectl wait --for=condition=ready pod -l ray.io/node-type=head   -n "$NAMESPACE" --timeout=900s
  kubectl wait --for=condition=ready pod -l ray.io/node-type=worker -n "$NAMESPACE" --timeout=900s

  echo "$(elapsed) >> waiting for postStart setup (verl + integration + model/data download)"
  for ROLE in head worker; do
    POD=$(kubectl get pod -n "$NAMESPACE" -l "ray.io/node-type=$ROLE" -o jsonpath='{.items[0].metadata.name}')
    for i in $(seq 1 120); do   # up to ~20 min
      if kubectl exec -n "$NAMESPACE" "$POD" -- test -f /tmp/verl_ready.txt 2>/dev/null; then
        echo "$(elapsed)    $ROLE ($POD) ready"; break
      fi
      [[ $i -eq 120 ]] && { echo "ERROR: $ROLE postStart did not finish; see: kubectl exec -n $NAMESPACE $POD -- cat /tmp/setup_log.txt"; exit 1; }
      sleep 10
    done
  done
fi

# --- 3. routing overrides ----------------------------------------------------
case "$MODE" in
  epp)
    ROUTING_OVERRIDES=(
      "+actor_rollout_ref.rollout.agent.agent_loop_manager_class=llm_d_rl_verl_integration.llmd_epp.agent_loop_manager.LlmdRouterAgentLoopManager"
      "+actor_rollout_ref.rollout.custom.epp_config_file=/etc/llmd-configs/epp-config.yaml"
      "+actor_rollout_ref.rollout.custom.epp_endpoints_file=/tmp/epp-endpoints.yaml"
    )
    EXP_NAME="demo_epp_2gpu" ;;
  native)
    ROUTING_OVERRIDES=(
      "+actor_rollout_ref.rollout.agent.agent_loop_manager_class=llm_d_rl_verl_integration.native_logging.agent_loop_manager.NativeLoggingAgentLoopManager"
      "+actor_rollout_ref.rollout.custom.epp_endpoints_file=/tmp/epp-endpoints.yaml"
    )
    EXP_NAME="demo_native_2gpu" ;;
  *)
    echo "ERROR: mode must be 'epp', 'native' or 'teardown' (got '$MODE')"; exit 1 ;;
esac

# --- 4. run training ---------------------------------------------------------
HEAD=$(kubectl get pod -n "$NAMESPACE" -l ray.io/node-type=head -o jsonpath='{.items[0].metadata.name}')
[[ -n "$HEAD" ]] || { echo "ERROR: no Ray head pod in namespace '$NAMESPACE'"; exit 1; }
echo "$(elapsed) >> training on $HEAD  (mode=$MODE, steps=$STEPS, n=$N, gpu_mem_util=$GPU_MEM_UTIL)"

kubectl exec -i -n "$NAMESPACE" "$HEAD" -- bash -s -- \
  "$STEPS" "$N" "$GPU_MEM_UTIL" "$EXP_NAME" "${ROUTING_OVERRIDES[@]}" <<'REMOTE'
set -euo pipefail
STEPS="$1"; N="$2"; GPU_MEM_UTIL="$3"; EXP_NAME="$4"; shift 4
ROUTING_OVERRIDES=("$@")

cd /tmp/verl/verl/examples/grpo_trainer

NGPUS_PER_NODE=2 \
TRAIN_BATCH_SIZE=32 \
PPO_MINI_BATCH_SIZE=16 \
MODEL_PATH=/tmp/verl/models/Qwen3-0.6B \
TRAIN_FILE=/tmp/verl/data/gsm8k/train.parquet \
TEST_FILE=/tmp/verl/data/gsm8k/test.parquet \
MAX_PROMPT_LENGTH=512 MAX_RESPONSE_LENGTH=512 \
SAVE_FREQ=-1 \
PROJECT_NAME=verl_grpo_gsm8k_examples \
EXPERIMENT_NAME="$EXP_NAME" \
bash /tmp/verl/verl/examples/grpo_trainer/run_qwen3_4b_fsdp.sh \
    actor_rollout_ref.rollout.tensor_model_parallel_size=1 \
    actor_rollout_ref.rollout.n="$N" \
    actor_rollout_ref.rollout.gpu_memory_utilization="$GPU_MEM_UTIL" \
    actor_rollout_ref.rollout.enforce_eager=True \
    actor_rollout_ref.rollout.max_model_len=2048 \
    actor_rollout_ref.rollout.max_num_batched_tokens=2048 \
    actor_rollout_ref.rollout.max_num_seqs=64 \
    trainer.logger='["console","file"]' \
    trainer.total_training_steps="$STEPS" \
    trainer.val_before_train=False \
    trainer.test_freq=-1 \
    trainer.default_local_dir=/tmp/checkpoints \
    +ray_kwargs.ray_init.runtime_env.env_vars.VERL_FILE_LOGGER_ROOT=/tmp/verl/logs \
    actor_rollout_ref.rollout.disable_log_stats=False \
    +actor_rollout_ref.rollout.engine_kwargs.vllm.enable_prompt_tokens_details=true \
    "${ROUTING_OVERRIDES[@]}" \
    hydra.run.dir=/tmp/hydra-outputs
REMOTE

echo "$(elapsed) >> done. Tear down with: bash $0 teardown"
