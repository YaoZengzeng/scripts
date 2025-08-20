#!/bin/bash

NAMESPACE="${1:-default}"

kubectl label namespace "$NAMESPACE" istio.io/dataplane-mode=ambient

istioctl waypoint apply -n "$NAMESPACE" --enroll-namespace
