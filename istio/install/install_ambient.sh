#!/bin/bash

kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl apply -f -; }


istioctl install --set profile=ambient --skip-confirmation --set meshConfig.accessLogFile="/dev/stdout" --set components.ingressGateways[0].enabled=true --set components.ingressGateways[0].name=istio-ingressgateway #--set values.cni.ambient.redirectMode="ebpf"

# If you want to pull images from local registry, add config `--set hub="localhost:5000/istio"`
