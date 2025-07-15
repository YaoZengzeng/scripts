#!/bin/bash

# deploy vllm simulator

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/vllm/sim-deployment.yaml

# install the inference extension CRD

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/latest/download/manifests.yaml

# deploy InferenceModel

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/inferencemodel.yaml

# deploy InferencePool and Endpoint Picker Extension

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/inferencepool-resources.yaml

### install istio

TAG=1.27-alpha.0551127f00634403cddd4634567e65a8ecc499a7

wget https://storage.googleapis.com/istio-build/dev/$TAG/istioctl-$TAG-linux-amd64.tar.gz

tar -xvf istioctl-$TAG-linux-amd64.tar.gz

./istioctl install --set tag=$TAG --set hub=gcr.io/istio-testing

# destination rule to skip verification

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/destination-rule.yaml

# deploy gateway

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/gateway.yaml

# label the gateway

kubectl label gateway inference-gateway istio.io/enable-inference-extproc=true

# confirm that the gateway was assigned an IP address and reports a `Programmed=True` status.

kubectl get gateway inference-gateway

# deploy HTTPRoute

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/httproute.yaml

# confirm that the HTTPRoute status conditions include `Accepted=True` and `ResolvedRefs=True`

kubectl get httproute llm-route -o yaml
