#!/bin/bash

MODE=with-envoy
VERSION=v1.13.0

if [ "$MODE" == "raw" ]; then
	cilium install --version $VERSION
elif [ "$MODE" == "with-envoy" ]; then
	cilium install \
	  --kube-proxy-replacement=strict \
	  --helm-set-string extraConfig.enable-envoy-config=true \
	  --helm-set loadBalancer.l7.backend=envoy \
	  --helm-set prometheus.enabled=true \
	  --helm-set operator.prometheus.enabled=true \
	  --helm-set hubble.enabled=true \
	  --helm-set hubble.metrics.enableOpenMetrics=true \
	  --helm-set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
	  --version $VERSION
fi

# avoid "too many open files" error
sysctl -w fs.inotify.max_user_watches=100000
sysctl -w fs.inotify.max_user_instances=100000

cilium hubble enable
