#!/bin/bash

NAMESPACE="${2:-default}"

# Delete after full verification
#
#if [ "$IPV6" = "true" ]; then
#	kubectl exec "$1" -n "$NAMESPACE" -- curl [::]:15000/config_dump?include_eds > envoy.dump
#else
#	kubectl exec "$1" -n "$NAMESPACE" -- curl 127.0.0.1:15000/config_dump?include_eds > envoy.dump
#fi

istioctl pc all $1.$NAMESPACE -o json > envoy.dump
