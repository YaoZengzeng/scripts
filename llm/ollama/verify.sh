#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

# Pull model first
curl http://localhost:11434/api/pull -d '{
  "name": "llama3.2"
}'

# Generate a completion
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?"
}'
