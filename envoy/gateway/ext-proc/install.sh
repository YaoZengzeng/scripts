#!/bin/bash

# Install a demo GRPC service which will be used as the external processing service
kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/latest/examples/kubernetes/ext-proc-grpc-service.yaml


# Create a new HTTPRoute resource to route traffic to path `/myapp` to the backend
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myapp
spec:
  parentRefs:
  - name: eg
  hostnames:
  - "www.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /myapp
    backendRefs:
    - name: backend
      port: 3000
EOF

# Create a new EnvoyExtensionPoliy resource to config the external processing service
cat <<EOF | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: ext-proc-example
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: myapp
  extProc:
  - backendRefs:
    - name: grpc-ext-proc
      port: 9002
    processingMode:
      request: {}
      response:
        body: Streamed
EOF

# Because the gRPC external processing service is enabled with TLS, a BackendTLSPolicy needs to be created to config the communication between proxy and the gRPC auth service
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1alpha3
kind: BackendTLSPolicy
metadata:
  name: grpc-ext-proc-btls
spec:
  targetRefs:
  - group: ''
    kind: Service
    name: grpc-ext-proc
    sectionName: "9002"
  validation:
    caCertificateRefs:
    - name: grpc-ext-proc-ca
      group: ''
      kind: ConfigMap
    hostname: grpc-ext-proc.envoygateway
EOF


