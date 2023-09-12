#!/bin/bash

cd ~

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.18.0 TARGET_ARCH=x86_64 sh -

cd istio-1.18.0

cp bin/istioctl /usr/local/bin/
