#!/bin/bash

VERSION="${1:-1.27.5}"

CLUSTER="${2:-kmesh-testing}"

kind load docker-image ghcr.io/yaozengzeng/pilot:$VERSION --name $CLUSTER
