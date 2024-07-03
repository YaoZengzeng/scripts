#!/bin/bash

NAMESPACE="${2:-default}"

kubectl exec "$1" -c istio-proxy -n "$NAMESPACE" -- curl -XPOST 127.0.0.1:15000/logging?level=trace
