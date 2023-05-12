#!/bin/bash

enable_local_dns=true

istioctl x precheck

if "$enable_local_dns"; then

cat <<EOF | istioctl install -y -f -
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
EOF

else
  istioctl install --set profile=demo -y
fi

kubectl label --overwrite namespace default istio-injection=enabled
