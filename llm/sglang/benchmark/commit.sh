#!/bin/bash

containerid="e4bf08c4374b"

image="ghcr.io/yaozengzeng/sglang-benchmark:qwen-7b"

docker commit $containerid $image

docker push $image
