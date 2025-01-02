#!/bin/bash

# ref: https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion

HOST="${HOST:-localhost:4000}"

# Generate a completion
curl -v http://$HOST/chat/completions -d '{
    "model": "llama3.2",
    "messages": [
        {
        "role": "user",
        "content": "what llm are you"
        }
    ],
    "metadata": {
        "generation_name": "ishaan-test-generation",
        "generation_id": "gen-id22",
        "trace_id": "trace-id22",
        "trace_user_id": "user-id2"
    }
}'
