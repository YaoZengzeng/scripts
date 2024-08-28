#!/bin/bash

NAMESPACE="${3:-default}"

NAME="$1"-"$2"-waypoint

istioctl x waypoint delete "$NAME" -n "$NAMESPACE" || istioctl waypoint delete "$NAME" -n "$NAMESPACE"

kubectl label pod -l app=$1,version=$2 istio.io/use-waypoint-
