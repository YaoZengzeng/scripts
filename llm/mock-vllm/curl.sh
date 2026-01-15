#!/bin/bash

POD="${1}"
MODEL="${2:-"deepseek-r1-1-5b"}"

if [ -z "$POD" ]; then
    echo "Usage: $0 POD [MODEL]"
    echo "Example: $0 deepseek-r1-1-5b-v1-7cf4bb4cb5-njqqx deepseek-r1-1-5b"
    exit 1
fi

kubectl exec $POD -- curl -v http://127.0.0.1:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"San Francisco is a\",
        \"temperature\": 0
    }"