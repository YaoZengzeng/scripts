#!/bin/bash

NAMESPACE="${1:-default}"

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/bookinfo/platform/kube/bookinfo.yaml -n "$NAMESPACE"

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/sleep/sleep.yaml -n "$NAMESPACE"

