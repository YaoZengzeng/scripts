#!/bin/bash

python3 -m dynamo.mocker \
    --model-path Qwen/Qwen3-0.6B \
    --disaggregation-mode prefill \
    --bootstrap-ports 50100
