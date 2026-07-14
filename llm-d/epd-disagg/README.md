# Qwen2-VL-2B — EPD disaggregation (native vLLM, no llm-d)

Deploy the multimodal model **Qwen/Qwen2-VL-2B-Instruct** on Kubernetes with
**E / P / D (Encode → Prefill → Decode) disaggregation**, using vLLM's *native*
[Disaggregated Encoder](https://docs.vllm.ai/en/latest/features/disagg_encoder/)
feature. This is the simplest way to run EPD without the llm-d / coordinator
stack.

Two topologies are provided:

| Topology   | Manifest                                               | Hardware                | When to use                                         |
| ---------- | ------------------------------------------------------ | ----------------------- | --------------------------------------------------- |
| **single** | [epd-deployment.yaml](epd-deployment.yaml)             | 1 GPU, 1 node           | All engines share one GPU in one Pod                |
| **2node**  | [epd-deployment-2node.yaml](epd-deployment-2node.yaml) | 2-GPU node + 1-GPU node | Full E/P/D, one engine per GPU, **no StorageClass** |

```bash
./deploy.sh              # single-GPU (default)
./deploy.sh 2node        # 2-GPU node + 1-GPU node, no shared storage needed
```

## What this is

vLLM engines run as **separate processes inside one Pod**, all sharing the single
GPU (`CUDA_VISIBLE_DEVICES=0`), fronted by a small OpenAI-compatible proxy. Two
layouts are supported via the `DISAGG_MODE` env var:

### `1e1pd` — Encode + combined Prefill/Decode (default, recommended)

Two engines. The **encoder is disaggregated** (its own process, `--mm-encoder-only`),
while prefill+decode share one engine. No NIXL. Fits comfortably on a 20 GB GPU.

```
                         ┌──────────────── one Pod, one GPU ────────────────┐
client ──> Service :8000 │  proxy (:8000)                                    │
                         │    │  1. fan out image → Encode (:8001, mm-only)  │
                         │    │       └─ encoder-cache → /dev/shm (EC conn)  │
                         │    └> 2. Prefill+Decode (:8003, EC consumer)      │
                         └──────────────────────────────────────────────────┘
```

### `1e1p1d` — full Encode + Prefill + Decode (opt-in, tight on 20 GB)

Three engines; Prefill→Decode KV transferred via `NixlConnector`. Each of P and D
loads the full 4.26 GB model, so KV-cache headroom is small on 20 GB — keep
`MAX_MODEL_LEN` low.

```
  proxy → Encode (:8001) ─EC→ Prefill (:8002) ─KV via NIXL→ Decode (:8003)
```

- **Encode → Prefill**: encoder-cache (image embeddings) via `ECExampleConnector`
  (shared `/dev/shm`).
- **Prefill → Decode**: KV cache via `NixlConnector`.
- A single physical GPU can only be claimed by one Pod, so all engines live in one
  Pod/container rather than three Deployments.

## Files

| File                                                   | Purpose                                                                                |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| [epd-deployment.yaml](epd-deployment.yaml)             | **single**: Namespace, Secret, ConfigMap (startup script + proxy), Deployment, Service |
| [epd-deployment-2node.yaml](epd-deployment-2node.yaml) | **2node**: role-based ConfigMap + epd-ep (encode+prefill, 2 GPUs) / epd-decode / proxy |
| [deploy.sh](deploy.sh)                                 | Apply manifests and wait for rollout — `./deploy.sh [single\|2node]`                   |
| [verify.sh](verify.sh)                                 | Port-forward `svc/epd-proxy` and send a real image+text request                        |

## Prerequisites

- A Kubernetes cluster with 1x NVIDIA GPU (~20 GB, e.g. RTX 4000 Ada) exposed via
  the NVIDIA device plugin (`nvidia.com/gpu`).
- A vLLM image that includes the **Disaggregated Encoder / EC transfer** feature.
  This is recent (main branch), so the manifest uses `vllm/vllm-openai:nightly`.
  Pin a specific nightly digest for reproducibility if desired.
- Pod egress to Hugging Face (model download) and to the test image URL.

## Usage

```bash
cd /root/scripts/llm-d/epd-disagg
./deploy.sh      # apply + wait (model download + 3 engines can take minutes)
./verify.sh      # sends an image+text chat request through the EPD proxy
```

Follow logs:

```bash
kubectl -n epd-disagg logs -f deploy/epd-disagg
```

## Single-GPU memory tuning (20 GB)

`gpu_memory_utilization` is a fraction of **total** device memory, and all engines
share the one GPU, so their fractions plus CUDA-context overhead must stay under
~1.0. Set via env in the Deployment:

| Mode     | Env          | Default | Notes                                         |
| -------- | ------------ | ------- | --------------------------------------------- |
| both     | `GPU_MEM_E`  | `0.20`  | Encode, `--mm-encoder-only` (~1.2 GB weights) |
| `1e1pd`  | `GPU_MEM_PD` | `0.75`  | Combined Prefill/Decode engine                |
| `1e1p1d` | `GPU_MEM_P`  | `0.38`  | Prefill (only used in 3-way mode)             |
| `1e1p1d` | `GPU_MEM_D`  | `0.38`  | Decode  (only used in 3-way mode)             |

Defaults: `MAX_MODEL_LEN=4096`, `MAX_NUM_SEQS=16`.

**If you see `No available memory for the cache blocks` / `Available KV cache
memory: -X GiB`** (the failure this deployment originally hit in 3-way mode), the
engine has no room left for KV cache after weights + activations. Fix by:

- Prefer `DISAGG_MODE=1e1pd` (the default) — the combined engine gets ~15 GB.
- For `1e1p1d`: lower `MAX_MODEL_LEN` (e.g. `2048`) and `MAX_NUM_SEQS` (e.g. `8`),
  and/or raise `GPU_MEM_P` / `GPU_MEM_D` (keeping `E + P + D < ~0.95`).

## Switching to full 3-way EPD

Set on the Deployment (and expect to tune memory as above):

```yaml
- name: DISAGG_MODE
  value: "1e1p1d"
```

This starts a dedicated Prefill engine (NIXL producer) and Decode engine (NIXL
consumer); the proxy primes prefill then streams from decode.

## 2node: full E / P / D across a 2-GPU node + a 1-GPU node — no StorageClass

Have **one node with 2 GPUs and another with 1 GPU** (3 GPUs total)? Use
[epd-deployment-2node.yaml](epd-deployment-2node.yaml) via `./deploy.sh 2node`.
This runs **full 3-way EPD** — one engine per GPU, each owning a whole ~20 GB
GPU (no memory contention) — and needs **no shared storage at all** (no PVC, no
`hostPath`, no `storageClassName`).

```
 client → Service epd-proxy:8000 → proxy Pod (no GPU)
     ├─ Encode  Service → epd-ep Pod / encode  container  ┐ same Pod,
     ├─ Prefill Service → epd-ep Pod / prefill container  ┘ 2-GPU node
     └─ Decode  Service → epd-decode Pod                    (1-GPU node)
 encode ─(EC cache, in-Pod emptyDir)→ prefill ─(NIXL KV over net)→ decode
```

How it dodges shared storage:

- **Encode + Prefill live in ONE Pod** (`epd-ep`) as two containers, each
  requesting 1 GPU → the Pod needs 2 GPUs, so it can only land on the **2-GPU
  node**. Because they're in the same Pod, the **EC encoder cache** is just a
  plain **in-Pod `emptyDir`** they both mount at `/ec-cache` — **no hostPath, no
  RWX PVC, no `storageClassName`**.
- **Decode is its own Pod** requesting 1 GPU. The 2-GPU node is already full, so
  it lands on the **1-GPU node** (a `preferred` anti-affinity to `epd-ep` makes
  that explicit). **Prefill → Decode** KV cache travels over the **pod network**
  via `NixlConnector` (side-channel port `5559`) — no storage needed.

Roles are selected by the `ROLE` env var (`encode|prefill|decode|proxy`) in the
shared `start-role.sh`. `GPU_MEM_*` default to `0.90` and `MAX_MODEL_LEN` to
`8192`.

### 2node prerequisites

- One node with **2** `nvidia.com/gpu` and one node with **1** `nvidia.com/gpu`.
- Cluster networking that allows Pod-to-Pod traffic on port `5559` across the two
  nodes (default CNIs do; adjust NetworkPolicies if you use them).

## Caveats

- The Disaggregated Encoder (EC transfer) and cross-process NixlConnector on a
  **shared** GPU are **experimental** in vLLM. Expect to tune memory fractions.
- `Qwen/Qwen2-VL-2B-Instruct` follows the same code path as the upstream example
  model `Qwen/Qwen2.5-VL-3B-Instruct`; if you see model-specific issues, try
  `MODEL=Qwen/Qwen2.5-VL-3B-Instruct` (needs more VRAM).
- `emptyDir` is used for the HF cache — weights re-download on Pod restart. Swap
  for a `PVC` to persist them.
- This intentionally does **not** use llm-d, the coordinator repo, Gateway API,
  EPP or InferencePools — it is the minimal native-vLLM EPD path.
