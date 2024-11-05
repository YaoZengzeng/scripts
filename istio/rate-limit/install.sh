#!/bin/bash

# Install bookinfo with gateway first

kubectl apply -f filter-ratelimit
kubectl apply -f filter-ratelimit-svc
kubectl apply -f filter-ratelimit-svc-api
kubectl apply -f ratelimit-config
kubectl apply -f virtualservice
kubectl apply -f filter-ratelimit-svc

