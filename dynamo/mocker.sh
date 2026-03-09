#!/bin/bash

cd /root/dynamo

container/run.sh --image nvcr.io/nvidia/ai-dynamo/vllm-runtime:0.9.0 --gpus none -it --     bash -c "nats-server -js >/dev/null 2>&1 & python3 -m dynamo.mocker --model-path Qwen/Qwen3-0.6B --speedup-ratio 10.0 --store-kv mem"
