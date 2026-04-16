#!/bin/bash

docker run -e MODEL="deepseek-r1" \
           -e BASE_URL="http://127.0.0.1:80" \
           -e SAVE_FILE_KEY="benchmark_results" \
           -e SCENARIOS="all" \
           -e QPS_VALUES="1.34 2.0 3.0" \
           -v /root/llm-bench-result:/app/results \
	   --network host \
           ghcr.io/yaozengzeng/inference-benchmark:latest
