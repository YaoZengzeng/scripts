#!/bin/bash

kubectl delete -f https://raw.githubusercontent.com/envoyproxy/gateway/latest/examples/kubernetes/ext-proc-grpc-service.yaml
kubectl delete httproute/myapp
kubectl delete envoyextensionpolicy/ext-proc-example
kubectl delete backendtlspolicy/grpc-ext-proc-btls

