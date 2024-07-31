#!/bin/bash

kubectl label namespace default istio.io/dataplane-mode=Kmesh

bash all-in-one.sh

istioctl x waypoint apply -n default --name reviews-svc-waypoint

kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint

kubectl annotate gateway reviews-svc-waypoint sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest
