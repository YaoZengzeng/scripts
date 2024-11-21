#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

HOST="${HOST:-localhost:11434}"

# Pull model first
curl --header "Host: www.ollama.com" http://$HOST/api/pull -d '{
  "name": "llama3.2"
}'

# List local models
curl --header "Host: www.ollama.com" http://$HOST/api/tags

# Generate a completion
curl --header "Host: www.ollama.com" http://$HOST/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?"
}'
