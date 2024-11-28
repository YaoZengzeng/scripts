#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

HOST="${HOST:-localhost:11434}"

# Generate a completion
curl -v --header "Host: www.ollama.com" http://$HOST/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Who are you?"
}'
