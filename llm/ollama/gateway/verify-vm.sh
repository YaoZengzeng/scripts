#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

loop_count=1

if [ $# -ge 1 ]; then
  loop_count=$1
fi

HOST="${HOST:-localhost:11434}"

for (( i=1; i<=loop_count; i++ )); do
  # Generate a completion
  curl -v --header "Host: www.ollama.com" http://$HOST/api/generate -d '{
    "model": "llama",
    "prompt": "Who are you?"
  }'
done