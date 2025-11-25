#!/bin/bash

# deploy vllm simulator

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/vllm/sim-deployment.yaml

# Install the Inference Extension CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/latest/download/manifests.yaml

# Deploy the InferencePool and Endpoint Picker Extension

export GATEWAY_PROVIDER=istio
helm install vllm-llama3-8b-instruct \
--set inferencePool.modelServers.matchLabels.app=vllm-llama3-8b-instruct \
--set provider.name=$GATEWAY_PROVIDER \
--version v1.0.0 \
oci://registry.k8s.io/gateway-api-inference-extension/charts/inferencepool

### install istio

TAG=$(curl https://storage.googleapis.com/istio-build/dev/1.28-dev)

wget https://storage.googleapis.com/istio-build/dev/$TAG/istioctl-$TAG-linux-amd64.tar.gz
tar -xvf istioctl-$TAG-linux-amd64.tar.gz

./istioctl install --set tag=$TAG --set hub=gcr.io/istio-testing --set values.pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true

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
