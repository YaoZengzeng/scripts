#!/bin/bash

NAMESPACE="${1:-default}"

IMAGE="ghcr.io/yaozengzeng/waypoint:latest"

kmeshctl waypoint apply -n "$NAMESPACE" --enroll-namespace --image $IMAGE
