#!/bin/bash

# access through gateway
# kubectl exec deploy/loadclient -- /usr/bin/fortio load -qps -1 -c 1 -t 10s -payload-size 1000 --timeout 120s  http://istio-ingressgateway.istio-system

# access through directly
kubectl exec deploy/loadclient -- /usr/bin/fortio load -qps -1 -c 64 -t 60s --timeout 120s  http://fortio.default:8080
