#!/bin/bash

NAMESPACE="${2:-default}"

kubectl exec "$1" -c istio-proxy -n "$NAMESPACE" -- curl 127.0.0.1:15000/config_dump > envoy_sidecar.dump
