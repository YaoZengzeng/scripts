#!/bin/bash

docker run -it --network host ghcr.io/yaozengzeng/sglang-benchmark:qwen-7b --host 127.0.0.1 --port 80 --model deepseek-ai/DeepSeek-R1-Distill-Qwen-7B --tokenizer deepseek-ai/DeepSeek-R1-Distill-Qwen-7B
