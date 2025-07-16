#!/bin/bash

containerid="2a50eba55855"

image="ghcr.io/yaozengzeng/sglang-benchmark:qwen-7b"

docker commit $containerid $image

docker push $image
