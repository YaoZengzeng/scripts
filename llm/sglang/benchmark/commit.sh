#!/bin/bash

containerid="${1:-30766fbc6413}"

image="ghcr.io/yaozengzeng/sglang-benchmark:qwen-7b"

docker commit $containerid $image

docker push $image
