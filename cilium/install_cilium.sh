#!/bin/bash

MODE=with-envoy
VERSION=v1.13.0

if [ "$MODE" == "raw" ]; then
	cilium install --$VERSION
elif [ "$MODE" == "with-envoy" ]; then
	cilium install \
	  --kube-proxy-replacement=strict \
	  --helm-set-string extraConfig.enable-envoy-config=true \
	  --helm-set loadBalancer.l7.backend=envoy \
	  --version $VERSION
fi

cilium hubble enable
