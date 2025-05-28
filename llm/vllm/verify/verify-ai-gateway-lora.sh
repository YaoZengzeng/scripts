#!/bin/bash

MODEL="${1:-"Lora-A"}"

HOST="${HOST:-127.0.0.1:8080}"

curl -v http://$HOST/v1/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"San Francisco is a\",
        \"temperature\": 0
    }"
