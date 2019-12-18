#!/bin/bash

K8S_API_SERVER_IP=

# Start kubelet
nohup kubelet \
  --api-servers=http://$K8S_API_SERVER_IP:8080 \
  --v=2 \
  --address=0.0.0.0 \
  --enable-server=true \
  --network-plugin=cni \
  --network-plugin-dir=/etc/cni/net.d \
  2>&1 > /dev/null &

