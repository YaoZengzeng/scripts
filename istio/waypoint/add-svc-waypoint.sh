#!/bin/bash

NAMESPACE="${2:-default}"

NAME="$1"-svc-waypoint

IMAGE="ghcr.io/yaozengzeng/waypoint:latest"

kmeshctl waypoint apply -n $NAMESPACE --name "$NAME" --image $IMAGE

kubectl label service "$1" istio.io/use-waypoint="$NAME" -n "$NAMESPACE"
