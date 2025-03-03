#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

HOST="${HOST:-localhost:11434}"

MODEL="${1:-"llama3.1"}"

# Generate a completion
curl -v --header "Host: www.ollama-test.com" http://$HOST/api/generate -d "{
  \"model\": \"$MODEL\",
  \"prompt\": \"Who are you?\"
}"
