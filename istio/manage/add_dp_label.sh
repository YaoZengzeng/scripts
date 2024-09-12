#!/bin/bash

NAMESPACE="${1:-default}"
MODE="${2:-Kmesh}"

kubectl label namespace "$NAMESPACE" istio.io/dataplane-mode=$MODE

kubectl get namespace -L istio.io/dataplane-mode
