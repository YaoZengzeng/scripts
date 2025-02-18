#!/bin/bash

TOKEN=$(cat /root/huggingface-token)

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"}"

LORA1="/root/.cache/huggingface/hub/models--riyazahuja--DeepSeek-R1-Distill-Qwen-1.5B_demo/snapshots/63d9d446f926dbf1442588e17c0a9550c771e1d0"

# Models:
#   NousResearch/Llama-2-7b-hf

echo "run model $MODEL"

docker run --env "HUGGING_FACE_HUB_TOKEN=$TOKEN" -v /root/.cache/huggingface:/root/.cache/huggingface -p 8000:8000 --ipc=host ghcr.io/yaozengzeng/vllm-cpu-env --model $MODEL --enable-lora --lora-modules ds-lora=$LORA1 --max_lora_rank 128
