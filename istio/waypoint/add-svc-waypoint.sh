#!/bin/bash

NAMESPACE="${2:-default}"

NAME="$1"-svc-waypoint

istioctl x waypoint apply -n $NAMESPACE --name "$NAME"

kubectl annotate gateway $NAME sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest -n "$NAMESPACE"

kubectl label service "$1" istio.io/use-waypoint="$NAME"
