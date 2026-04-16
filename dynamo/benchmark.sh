#!/bin/bash

URL=${URL:-http://localhost:8000}

MODEL=${MODEL:-Qwen/Qwen3-0.6B}

aiperf profile \
    --model "$MODEL" \
    --url "$URL" \
    --endpoint-type chat \
    --streaming \
    --concurrency 10 \
    --request-count 100 \
    --synthetic-input-tokens-mean 2000 \
    --output-tokens-mean 256
