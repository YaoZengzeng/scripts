#!/bin/bash

POD1="ds-r1-qwen-7b-new-0-vllm-instance-0-leader-0-0"
POD2="ds-r1-qwen-7b-new-0-vllm-instance-1-leader-0-0"
POD3="ds-r1-qwen-7b-new-0-vllm-instance-2-leader-0-0"

# num_requests_waiting
# num_requests_running
# gpu_cache_usage_perc
# time_per_output_token_seconds
# time_to_first_token_seconds
METRIC="${1:-"gpu_cache_usage_perc"}"

kubectl exec $POD1 -n yzz -c engine -- curl 127.0.0.1:8000/metrics | grep $METRIC
echo
kubectl exec $POD2 -n yzz -c engine -- curl 127.0.0.1:8000/metrics | grep $METRIC
echo
kubectl exec $POD3 -n yzz -c engine -- curl 127.0.0.1:8000/metrics | grep $METRIC
