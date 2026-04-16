#!/bin/bash

TOKEN=$(cat /root/huggingface-token)

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"}"

LORA1="/root/.cache/huggingface/hub/models--riyazahuja--DeepSeek-R1-Distill-Qwen-1.5B_demo/snapshots/63d9d446f926dbf1442588e17c0a9550c771e1d0"
LORA2="/root/.cache/huggingface/hub/models--Zhidian2025--deepseek-r1-distill-finetuned/snapshots/02fac1b85668ea2aba62e7c7e37ce1a5d7d48d29"

# Models:
#   NousResearch/Llama-2-7b-hf

docker run --env "HUGGING_FACE_HUB_TOKEN=$TOKEN" --rm -v /root/.cache/huggingface:/root/.cache/huggingface -p 8000:8000 \
    --ipc=host ghcr.io/yaozengzeng/vllm-cpu-env --model $MODEL \
    --enable-lora --lora-modules ds-lora1=$LORA1 ds-lora2=$LORA2 \
    --max_lora_rank 128
