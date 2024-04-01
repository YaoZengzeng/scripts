#!/bin/bash

cp /root/yzz/istio/out/linux_amd64/pilot-discovery .

docker build . --no-cache -t istio/pilot:1.20.0-distroless
