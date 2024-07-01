#!/bin/bash

kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "localtrace"
EOF


# 需要修改Meshconfig添加provider的配置
# data:
#   mesh: |-
#       extensionProviders:
#       - name: "localtrace"
#         zipkin:
#           service: "zipkin.istio-system.svc.cluster.local"
#           port: 9411
#           maxTagLength: 56
#       defaultConfig:
#         tracing: {}
