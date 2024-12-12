#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

HOST="${HOST:-localhost:11434}"
MODEL=${model:-llama3.2}

# Pull model first
curl --header "Host: www.ollama.com" http://$HOST/api/pull -d '{
  "name": "codellama:34b-code-q4_K_M"
}'

# List local models
curl --header "Host: www.ollama.com" http://$HOST/api/tags
