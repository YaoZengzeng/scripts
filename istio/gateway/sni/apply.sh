#!/bin/sh

# Make sure delete the gateway "echo-tcp-gateway" since it's already using the tcp port.
kubectl delete gateway echo-tcp-gateway

kubectl apply -f simple-tls-service-1.yaml
kubectl apply -f simple-tls-service-2.yaml
kubectl apply -f passthrough-sni-gateway-both.yaml
kubectl apply -f passthrough-sni-vs-1.yaml
kubectl apply -f passthrough-sni-vs-2.yaml

