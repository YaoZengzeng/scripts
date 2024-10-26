#!/bin/bash

NAMESPACE="${3:-default}"

NAME="$1"-"$2"-pod-waypoint

IMAGE="ghcr.io/yaozengzeng/waypoint:latest"

kmeshctl waypoint apply -n $NAMESPACE --name $NAME --for workload --image $IMAGE

kubectl label pod -l app=$1,version=$2 istio.io/use-waypoint=$NAME
