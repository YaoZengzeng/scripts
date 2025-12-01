#!/bin/bash

# delete the InferencePool and InferenceModel
helm uninstall vllm-llama3-8b-instruct

# delete the vllm simulator
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/vllm/sim-deployment.yaml --ignore-not-found

# uninstall the gateway API Inference Extension

kubectl delete -k https://github.com/kubernetes-sigs/gateway-api-inference-extension/config/crd --ignore-not-found

# delete gateway, destination rule and httproute

kubectl delete -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/gateway.yaml --ignore-not-found
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/destination-rule.yaml --ignore-not-found
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/httproute.yaml --ignore-not-found
