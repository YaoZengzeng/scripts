#!/bin/bash

NAMESPACE="${2:-default}"

NAME="$1"-svc-waypoint

kmeshctl waypoint delete "$NAME" -n "$NAMESPACE"

kubectl label service "$1" istio.io/use-waypoint-
