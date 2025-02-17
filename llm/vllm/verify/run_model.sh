#!/bin/bash

TOKEN=xxxx

MODEL="${1:-"mistralai/Mistral-7B-v0.1"}"

echo "run model $MODEL"

docker run --env "HUGGING_FACE_HUB_TOKEN=$TOKEN" -p 8000:8000 --ipc=host ghcr.io/yaozengzeng/vllm-cpu-env --model $MODEL
