#!/bin/bash

docker create --name temp -v cache:/home/.cache busybox

if [ "$ARCH" = "arm" ]; then
	docker cp temp:/home/.cache/bazel/_bazel_root/1e0bb3bee2d09d2e4ad3523530d3b40c/execroot/io_istio_proxy/bazel-out/aarch64-opt/bin/envoy .
else
	docker cp temp:/home/.cache/bazel/_bazel_root/1e0bb3bee2d09d2e4ad3523530d3b40c/execroot/io_istio_proxy/bazel-out/k8-opt/bin/envoy .
fi

docker rm temp

if [ "$ARCH" = "arm" ]; then
	docker build . --no-cache -t ghcr.io/kmesh-net/waypoint-arm:latest
elif [ "$ARCH" = "x86" ]; then
	docker build . --no-cache -t ghcr.io/kmesh-net/waypoint-x86:latest
else
	docker build . --no-cache -t ghcr.io/kmesh-net/waypoint:latest
fi
