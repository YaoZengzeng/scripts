#!/bin/bash

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"}"

curl -v http://localhost:8080/v1/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"San Francisco is a\",
        \"temperature\": 0
    }"
