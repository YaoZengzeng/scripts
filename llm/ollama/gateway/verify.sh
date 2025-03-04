#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

#HOST="${HOST:-localhost:11434}"
HOST="${HOST:-172.18.0.0}"

MODEL="${1:-"deepseek-r1:1.5b"}"

# Generate a completion
curl -v http://$HOST/api/generate -d "{
  \"model\": \"$MODEL\",
  \"prompt\": \"Who are you?\"
}"
