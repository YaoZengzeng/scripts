#!/bin/bash

NAMESPACE="${1:-default}"

istioctl experimental waypoint apply -n "$NAMESPACE" --enroll-namespace || istioctl waypoint apply -n "$NAMESPACE" --enroll-namespace

# For Kmesh, change the image
kubectl annotate gateway waypoint sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest -n "$NAMESPACE"
