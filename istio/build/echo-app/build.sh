#!/bin/bash

cp /root/istio/out/linux_amd64/client .
cp /root/istio/out/linux_amd64/server .

docker build . --no-cache -t ghcr.io/yaozengzeng/app:latest

docker push ghcr.io/yaozengzeng/app:latest

rm client server
