#!/bin/bash

curl -v http://172.233.70.170:80/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"sglang-qwen-06b","messages":[{"role":"user","content":"Hello"}]}'
