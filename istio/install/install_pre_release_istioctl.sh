#/bin/bash

ISTIO_VERSION=${1:-"1.24.0-alpha.0"}

cd ~

wget https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-linux-amd64.tar.gz

tar -xzvf istio-$ISTIO_VERSION-linux-amd64.tar.gz

cd istio-$ISTIO_VERSION

cp bin/istioctl /usr/local/bin/
