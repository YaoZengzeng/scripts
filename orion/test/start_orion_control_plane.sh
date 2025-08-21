#!/bin/bash

docker run \
  --network host \
  -v /root/orion/orion-proxy/conf/orion-runtime-xds.yaml:/etc/orion/orion-runtime.yaml \
  orion-proxy
