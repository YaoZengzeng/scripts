#!/bin/bash

cd /root/gateway-api-inference-extension

export IMAGE_TAG="ghcr.io/yaozengzeng/gateway-api-inference-extension:latest"

make image-build

docker push ghcr.io/yaozengzeng/gateway-api-inference-extension:latest
