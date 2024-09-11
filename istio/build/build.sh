#!/bin/bash

VERSION="${1:-1.23.0}"

cp /root/istio/out/linux_amd64/pilot-discovery .

docker build . --no-cache -t istio/pilot:$VERSION-distroless
