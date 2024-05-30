#!/bin/bash

kubectl label namespace default istio.io/dataplane-mode-
kubectl label namespace default istio.io/use-waypoint-

istioctl x waypoint delete --all

istioctl uninstall -y --purge

kubectl delete namespace istio-system
