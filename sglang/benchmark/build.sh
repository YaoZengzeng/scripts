#!/bin/bash

docker build --no-cache --secret id=HF_TOKEN,env=HF_TOKEN --build-arg MODEL_ID=Qwen/Qwen3-0.6B -t ghcr.io/yaozengzeng/benchmark:qwen-3-0.6b .
