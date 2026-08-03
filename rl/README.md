# Minimal verl + llm-d EPP demo (2× ~20GB GPUs)

Smallest meaningful demo of the `integrations/verl` EPP routing on RTX 4000 Ada
(20GB) class GPUs: single-node, **2 GPUs**, GRPO on GSM8K with **Qwen3-0.6B**.

## Why 2 GPUs

verl runs rollout **colocated** with FSDP training on the same GPUs. The number of
vLLM replicas EPP can route between is `GPUs / tensor_parallel_size`. With `TP=1`,
2 GPUs give **2 replicas** — the minimum for EPP routing to mean anything. 1 GPU =
1 replica = routing is a no-op. The Ray head uses **no GPU** (it runs the driver +
EPP), so both GPUs go to the worker.

Qwen3-4B (the upstream default) OOMs colocated on a 20GB card, so this demo uses
Qwen3-0.6B. Model size is irrelevant for demonstrating routing.

## Topology

- Best: **1 node with 2 GPUs** (avoids cross-node NCCL entirely — these cards have
  no NVLink). 2 nodes × 1 GPU also works but trains slowly over Ethernet NCCL.
- **Node sizing**: head + worker co-locate on the same node, so their requests
  must fit together. Tuned for a **16 CPU / 64G** node: worker requests 8 CPU / 24G
  (limit 12 CPU / 34G) for FSDP + 2 vLLM workers; head requests 2 CPU / 14G (limit
  4 CPU / 26G) — the head is memory-heavy (driver + object store + EPP + the
  AgentLoop/Reward workers + sequence gathering), so it gets a large share.
  Limits sum to 60G, leaving headroom under 64G. The GPUs are still ~20GB each, so
  GPU-side knobs (`gpu_memory_utilization`, `enforce_eager`) stay modest.

## Files

- `ray-cluster.yaml.tmpl` — KubeRay manifest, edited from the upstream example:
  worker `nvidia.com/gpu: 2`, small head/worker cpu+memory (fits an 8C/32G node),
  `postStart` downloads Qwen3-0.6B instead of Qwen3-4B, faulty-node `nodeAffinity`
  removed. The `postStart` `pip install` of the integration is **pinned to commit
  `18812f2b`** — later upstream commits split out a separate `llm_d_rl_common`
  package that this flow does not install (unpinned installs fail at runtime with
  `ModuleNotFoundError: No module named 'llm_d_rl_common'`). `postStart` also
  **patches** the integration's head-node lookup: it matches the Ray head by the
  `node:__internal_head__` resource instead of by IP, because on KubeRay the head
  is addressed via a Service DNS name and the stock IP match fails
  (`RuntimeError: Could not find a live Ray node with GCS IP ...`).
- `run-demo.sh` — **one-shot** launcher: creates the namespace, deploys the
  cluster, waits for setup, and runs training. No other configuration needed.

## Run it (one command)

Prereqs: `kubectl` pointing at a cluster with 2 schedulable GPUs (as
`nvidia.com/gpu`) and the **KubeRay operator** installed
(`llm-d-rl/integrations/verl/deploy/kuberay/setting-kuberay.md`), and
`/root/llm-d-rl` present.

```bash
bash /root/scripts/rl/run-demo.sh            # deploy + EPP routing demo
bash /root/scripts/rl/run-demo.sh native     # baseline (verl native routing)
bash /root/scripts/rl/run-demo.sh teardown   # delete the cluster
```

`run-demo.sh` creates namespace `llm-d-rl-demo`, copies this 2-GPU template into
the repo's `deploy/kuberay/` (backing up the original as `*.orig`), runs the
upstream `deploy.sh apply` (which builds the EPP ConfigMap and injects images),
waits for both pods' `postStart` to finish (`/tmp/verl_ready.txt`), then execs the
training command on the head pod. Elapsed time is printed at each phase.

## 15-minute budget

Defaults are tuned to finish well under 15 min **once container images are
cached** on the node (first pull of the verl image is large and one-time):
Qwen3-0.6B, `STEPS=3`, batch 32, 512-token prompt/response, validation skipped
(`val_before_train=False`, `test_freq=-1`). The dominant costs are the one-time
image pull and the `postStart` setup (verl + integration install, model + GSM8K
download); training itself is a few minutes.

## Tuning

Env overrides for `run-demo.sh`: `NAMESPACE`, `REPO_DIR`, `STEPS` (default 3),
`N` (GRPO group, default 8), `GPU_MEM_UTIL` (default 0.5 — **lower to 0.4 / 0.3 if
you OOM**), and `SKIP_DEPLOY=1` to re-run training on an already-deployed cluster.
