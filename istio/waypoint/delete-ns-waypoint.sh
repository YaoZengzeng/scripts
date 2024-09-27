#!/bin/bash

NAMESPACE="${1:-default}"

kmeshctl waypoint delete waypoint

kubectl label ns "$NAMESPACE" istio.io/use-waypoint-
