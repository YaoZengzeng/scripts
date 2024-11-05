#!/bin/bash

NAMESPACE="${1:-default}"

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/bookinfo/platform/kube/bookinfo.yaml -n "$NAMESPACE"

# Create default destination rules for all Bookinfo services
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/networking/destination-rule-all.yaml -n "$NAMESPACE"

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/sleep/sleep.yaml -n "$NAMESPACE"

# Create ingress gateway
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/networking/bookinfo-gateway.yaml -n "$NAMESPACE"
