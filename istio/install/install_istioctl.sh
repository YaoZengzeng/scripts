#!/bin/bash

ISTIO_VERSION=${1:-"1.24.0"}

cd ~

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -

cd istio-${ISTIO_VERSION}

cp bin/istioctl /usr/local/bin/
