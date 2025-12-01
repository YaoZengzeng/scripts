#!/bin/bash

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"}"

PROMPT_LENGTH="${2:-20}"

HOST="${HOST:-127.0.0.1:80}"

PROMPT=$(printf 'h%.0s' $(seq 1 $PROMPT_LENGTH))

curl -v http://$HOST/v1/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"$PROMPT\",
        \"temperature\": 0
    }"
