#!/bin/bash

NAMESPACE="${2:-default}"

NAME="$1"-svc-waypoint

kmeshctl waypoint apply -n $NAMESPACE --name "$NAME"

kubectl label service "$1" istio.io/use-waypoint="$NAME" -n "$NAMESPACE"
