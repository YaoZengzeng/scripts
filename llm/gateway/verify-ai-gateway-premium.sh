#!/bin/bash

MODEL="${1:-"deepseek-r1"}"

HOST="${HOST:-127.0.0.1:80}"

curl -v http://$HOST/v1/completions \
    -H "Content-Type: application/json" \
    -H "user-type: premium" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"San Francisco is a\",
        \"temperature\": 0
    }"
