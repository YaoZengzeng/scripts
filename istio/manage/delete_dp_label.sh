#!/bin/bash

NAMESPACE="${1:-default}"

kubectl label namespace "$NAMESPACE" istio.io/dataplane-mode-

kubectl get namespace -L istio.io/dataplane-mode
