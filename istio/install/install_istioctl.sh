#!/bin/bash

cd ~

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.18.2 TARGET_ARCH=x86_64 sh -

cd istio-1.18.2

cp bin/istioctl /usr/local/bin/
