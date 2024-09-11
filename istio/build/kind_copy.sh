#!/bin/bash

VERSION="${1:-1.23.0}"

CLUSTER="${2:-kmesh}"

kind load docker-image istio/pilot:$VERSION-distroless --name $CLUSTER
