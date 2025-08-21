#!/bin/bash

docker run \
  --network host \
  -v ./orion-runtime-xds.yaml:/etc/orion/orion-runtime.yaml \
  orion-proxy
