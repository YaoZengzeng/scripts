#!/bin/bash

docker run --env "HUGGING_FACE_HUB_TOKEN=$1" -p 8000:8000 --ipc=host ghcr.io/yaozengzeng/vllm-cpu-env --model mistralai/Mistral-7B-v0.1
