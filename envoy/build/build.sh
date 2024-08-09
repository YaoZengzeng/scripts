#!/bin/bash

docker create --name temp -v cache:/home/.cache busybox

docker cp temp:/home/.cache/bazel/_bazel_root/1e0bb3bee2d09d2e4ad3523530d3b40c/execroot/io_istio_proxy/bazel-out/k8-opt/bin/envoy .

docker rm temp

docker build . --no-cache -t ghcr.io/kmesh-net/waypoint:latest
