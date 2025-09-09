#!/bin/bash

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"}"

HOST="${HOST:-127.0.0.1:80}"

curl http://$HOST/v1/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"San Francisco is a\",
        \"temperature\": 0
    }"
