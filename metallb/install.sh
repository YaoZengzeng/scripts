#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

kubectl wait --namespace metallb-system \
	--for=condition=ready pod \
	--selector=app=metallb \
	--timeout=90s

# Use command "docker network inspect -f '{{.IPAM.Config}}' kind" to update the IP range.
kubectl apply -f ipaddress-pool.yaml

# Install example
kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/usage.yaml

# Test
LB_IP=$(kubectl get svc/foo-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

# should output foo and bar on separate lines 
for _ in {1..10}; do
  curl ${LB_IP}:5678
done
