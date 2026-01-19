#!/bin/bash

VERSION="${1:-1.27.5}"

cp /root/istio/out/linux_amd64/pilot-discovery .

docker build . --no-cache -t ghcr.io/yaozengzeng/pilot:$VERSION
