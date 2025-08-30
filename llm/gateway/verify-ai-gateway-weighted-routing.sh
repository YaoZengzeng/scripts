#!/bin/bash

MODEL="${1:-"deepseek-subset"}"

HOST="${HOST:-127.0.0.1:80}"

for i in $(seq 1 100);
do
    curl http://$HOST/v1/completions \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"San Francisco is a\",
            \"temperature\": 0
        }";
done
