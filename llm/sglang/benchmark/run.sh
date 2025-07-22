#!/bin/bash

docker run -it --network host ghcr.io/yaozengzeng/sglang-benchmark:qwen-7b --host 127.0.0.1 --port 80 --model deepseek-ai/DeepSeek-R1-Distill-Qwen-7B --tokenizer deepseek-ai/DeepSeek-R1-Distill-Qwen-7B --dataset-name generated-shared-prefix --gsp-num-groups 256 --gsp-prompts-per-group 16 --gsp-system-prompt-len 256 --gsp-question-len 2048 --gsp-output-len 256 --request-rate 10 --max-concurrency 10 --max-concurrency 10
