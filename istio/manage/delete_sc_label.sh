#!/bin/bash

NAMESPACE="${1:-default}"

kubectl label namespace "$NAMESPACE" istio-injection-

kubectl get namespace -L istio-injection
