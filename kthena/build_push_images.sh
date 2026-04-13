#!/bin/bash

cd /root/kthena

export HUB="ghcr.io/yaozengzeng"
make docker-build-router

docker push ghcr.io/yaozengzeng/kthena-router:latest
