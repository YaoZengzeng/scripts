#!/bin/bash

cd /root/aibrix/development/app

docker build -t ghcr.io/yaozengzeng/deepseek-r1:mock -f Dockerfile .

docker push ghcr.io/yaozengzeng/deepseek-r1:mock
