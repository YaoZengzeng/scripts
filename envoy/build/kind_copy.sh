#!/bin/bash

CLUSTER=${1:-"kmesh-testing"}
REPO=${2:-"yaozengzeng"}

kind load docker-image ghcr.io/$REPO/waypoint:latest --name $CLUSTER
