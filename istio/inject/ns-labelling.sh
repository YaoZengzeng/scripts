#!/bin/bash

# enable sidecar inject
kubectl label namespace default istio-injection=enabled --overwrite

# disable sidecar inject
kubectl label namespace default istio-injection=disabled --overwrite

# viewing labels of ns
kubectl get namespace -L istio-injection
