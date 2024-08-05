#!/bin/bash

NAMESPACE="${1:-default}"

istioctl x waypoint delete waypoint

kubectl label ns "$NAMESPACE" istio.io/use-waypoint-
