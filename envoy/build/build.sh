#!/bin/bash

docker cp envoy_build_20:/home/.cache/bazel/_bazel_root/0b2f5c7fac4b02c7efd0f9f5b724b1fe/execroot/io_istio_proxy/bazel-out/k8-opt/bin/envoy .

docker build . --no-cache -t istio/proxyv2-dev:1.20.0
