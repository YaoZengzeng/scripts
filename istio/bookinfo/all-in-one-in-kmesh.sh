#!/bin/bash

NAMESPACE="${1:-default}"

kubectl label namespace "$NAMESPACE" istio.io/dataplane-mode=Kmesh

bash all-in-one.sh "$NAMESPACE"

kmeshctl waypoint apply -n "$NAMESPACE" --name reviews-svc-waypoint --image "ghcr.io/yaozengzeng/waypoint:latest"

kubectl label service reviews -n "$NAMESPACE" istio.io/use-waypoint=reviews-svc-waypoint
