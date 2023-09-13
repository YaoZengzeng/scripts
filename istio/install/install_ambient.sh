#!/bin/bash

kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
	  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.8.0" | kubectl apply -f -; }

istioctl install --set profile=ambient --set components.ingressGateways[0].enabled=true --set components.ingressGateways[0].name=istio-ingressgateway --skip-confirmation #--set values.cni.ambient.redirectMode="ebpf"

