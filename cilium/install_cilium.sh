#!/bin/bash

MODE=raw
VERSION=v1.13.0

if [ "$MODE" == "raw" ]; then
	cilium install --version $VERSION
elif [ "$MODE" == "with-envoy" ]; then
	cilium install \
	  --kube-proxy-replacement=strict \
	  --helm-set-string extraConfig.enable-envoy-config=true \
	  --helm-set loadBalancer.l7.backend=envoy \
	  --version $VERSION
fi

# avoid "too many open files" error
sysctl -w fs.inotify.max_user_watches=100000
sysctl -w fs.inotify.max_user_instances=100000

cilium hubble enable
