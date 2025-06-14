#!/bin/bash

HOST="${HOST:-"127.0.0.1:80"}"

MODEL="${1:-"deepseek-r1"}"

curl -v http://$HOST/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
	\"messages\": [{\"role\": \"user\", \"content\": \"Who are you?\"}],
        \"temperature\": 0,
	\"stream\": true
    }"
