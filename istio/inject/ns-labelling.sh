#!/bin/bash

# enable sidecar inject
kubectl label namespace default istio-injection=enabled --overwrite

# disable sidecar inject
kubectl label namespace default istio-injection=disabled --overwrite

# enable ambient
kubectl label namespace default istio.io/dataplane-mode=ambient

# viewing labels of ambient
kubectl get namespace -L istio.io/dataplane-mode

# viewing labels of ns
kubectl get namespace -L istio-injection

# delete istio.io/dataplane-mode label
kubectl  label namespace default istio.io/dataplane-mode-

