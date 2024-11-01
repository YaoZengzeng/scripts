#!/bin/bash

helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.1.2 -n envoy-gateway-system --create-namespace

kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

