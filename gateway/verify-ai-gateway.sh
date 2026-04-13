#!/bin/bash

MODEL="${1:-"deepseek-simple"}"

HOST="${HOST:-172.233.68.31:80}"

curl -v http://$HOST/v1/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"San Francisco is a\",
        \"temperature\": 0
    }"
