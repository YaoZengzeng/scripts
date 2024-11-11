#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

#HOST="localhost:11434"
HOST="172.18.0.0:80"

# Pull model first
curl http://$HOST/api/pull -d '{
  "name": "llama3.2"
}'

# List local models
curl http://$HOST/api/tags

# Generate a completion
curl http://$HOST/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?"
}'
