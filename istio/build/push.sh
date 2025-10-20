#!/bin/bash

VERSION="${1:-1.27.2}"

docker push ghcr.io/yaozengzeng/pilot:$VERSION-distroless
