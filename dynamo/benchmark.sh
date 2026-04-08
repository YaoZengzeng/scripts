#!/bin/bash

aiperf profile \
    --model Qwen/Qwen3-0.6B \
    --url http://localhost:8000 \
    --endpoint-type chat \
    --streaming \
    --concurrency 10 \
    --request-count 100 \
    --synthetic-input-tokens-mean 2000 \
    --output-tokens-mean 256
