#!/bin/sh

kubectl apply -f simple-web.yaml
kubectl apply -f simple-backend.yaml
kubectl apply -f simple-service-locality.yaml
kubectl apply -f simple-web-gateway.yaml
kubectl apply -f simple-backend-dr-outlier.yaml

# all traffic should go to simple-backend-1

# then apply simple-service-locality-failure.yaml, all traffic should go to simple-backend-2
