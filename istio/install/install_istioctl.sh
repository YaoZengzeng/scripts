#!/bin/bash

cd ~

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.15.4 TARGET_ARCH=x86_64 sh -

cd istio-1.15.4

cp bin/istioctl /usr/local/bin/
