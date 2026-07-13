# Qwen2-VL-2B — EPD disaggregation on a single GPU (native vLLM, no llm-d)

Deploy the multimodal model **Qwen/Qwen2-VL-2B-Instruct** on Kubernetes with
**E / P / D (Encode → Prefill → Decode) disaggregation**, using vLLM's *native*
[Disaggregated Encoder](https://docs.vllm.ai/en/latest/features/disagg_encoder/)
feature. This is the simplest way to run EPD without the llm-d / coordinator
stack.

## What this is

Three vLLM engines run as **separate processes inside one Pod**, all sharing the
single GPU (`CUDA_VISIBLE_DEVICES=0`), fronted by a small OpenAI-compatible proxy:

```
                         ┌─────────────────────── one Pod, one GPU ───────────────────────┐
client ──> Service :8000 │  proxy (:8000)                                                  │
                         │    │  1. fan out image → Encode (:8001, --mm-encoder-only)      │
                         │    │       └─ writes encoder-cache to /dev/shm (EC connector)   │
                         │    │  2. prime  Prefill (:8002)  ── KV via NixlConnector ──┐     │
                         │    └> 3. stream Decode  (:8003) <───────────────────────────┘     │
                         └────────────────────────────────────────────────────────────────┘
```

- **Encode → Prefill**: encoder-cache (image embeddings) transferred via the
  `ECExampleConnector` (shared `/dev/shm`).
- **Prefill → Decode**: KV cache transferred via `NixlConnector`.
- Single physical GPU can only be claimed by one Pod, so all engines live in one
  Pod/container rather than three Deployments.

## Files

| File                                       | Purpose                                                                    |
| ------------------------------------------ | -------------------------------------------------------------------------- |
| [epd-deployment.yaml](epd-deployment.yaml) | Namespace, Secret, ConfigMap (startup script + proxy), Deployment, Service |
| [deploy.sh](deploy.sh)                     | Apply manifests and wait for rollout                                       |
| [verify.sh](verify.sh)                     | Port-forward and send a real image+text request                            |

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

Set via env in the Deployment. Fractions are of total device memory; all three
must sum to leave headroom for CUDA contexts:

| Engine  | Env         | Default | Notes                                   |
| ------- | ----------- | ------- | --------------------------------------- |
| Encode  | `GPU_MEM_E` | `0.15`  | `--mm-encoder-only` (vision tower only) |
| Prefill | `GPU_MEM_P` | `0.35`  |                                         |
| Decode  | `GPU_MEM_D` | `0.35`  |                                         |

If you hit CUDA OOM, lower these and/or reduce `MAX_MODEL_LEN` (default `8192`)
and `MAX_NUM_SEQS` (default `64`).

## Fallback: E + PD (2 engines, no NIXL)

Full three-way EPD is the most fragile part (NIXL P→D transfer). To collapse to
**Encode + combined Prefill/Decode** (only the EC connector, no NixlConnector),
set on the Deployment:

```yaml
- name: PREFILL_URLS
  value: "disable"
```

The proxy then skips the prefill stage and sends encoded requests straight to the
PD engine. This is more robust and still demonstrates encoder disaggregation.

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
