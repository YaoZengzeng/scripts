#!/bin/bash

istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      enabled: true
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_DUAL_STACK: "true"
  values:
    pilot:
      env:
        ISTIO_DUAL_STACK: "true"
EOF
