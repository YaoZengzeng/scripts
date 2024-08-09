#!/bin/bash

NAMESPACE="${2:-default}"

if [ "$IPV6" = "true" ]; then
	kubectl exec "$1" -n "$NAMESPACE" -- curl -XPOST [::]:15000/logging?level=trace
else
	kubectl exec "$1" -n "$NAMESPACE" -- curl -XPOST 127.0.0.1:15000/logging?level=trace
fi
