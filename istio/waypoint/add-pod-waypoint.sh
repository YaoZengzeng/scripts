#!/bin/bash

NAMESPACE="${3:-default}"

NAME="$1"-"$2"-waypoint

istioctl x waypoint apply -n $NAMESPACE --name $NAME --for workload

kubectl annotate gateway $NAME sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest -n "$NAMESPACE"

kubectl label pod -l app=$1,version=$2 istio.io/use-waypoint=$NAME
