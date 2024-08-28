#!/bin/bash

NAMESPACE="${1:-default}"

kubectl label namespace "$NAMESPACE" istio.io/dataplane-mode=ambient

bash all-in-one.sh "$NAMESPACE"

istioctl x waypoint apply -n "$NAMESPACE" --name reviews-svc-waypoint || istioctl waypoint apply -n "$NAMESPACE" --name reviews-svc-waypoint

kubectl label service reviews -n "$NAMESPACE" istio.io/use-waypoint=reviews-svc-waypoint

# when deployed mixed with Kmesh, we need custom waypoint image
kubectl annotate gateway reviews-svc-waypoint -n "$NAMESPACE" sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest

