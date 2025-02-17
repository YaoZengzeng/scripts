#!/bin/bash

TOKEN=$(cat /root/huggingface-token)

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"}"

echo "run model $MODEL"

docker run --env "HUGGING_FACE_HUB_TOKEN=$TOKEN" -v /root/.cache/huggingface:/root/.cache/huggingface -p 8000:8000 --ipc=host ghcr.io/yaozengzeng/vllm-cpu-env --model $MODEL
