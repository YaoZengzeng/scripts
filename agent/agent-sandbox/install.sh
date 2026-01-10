#!/bin/bash

# https://github.com/kubernetes-sigs/agent-sandbox/releases
export VERSION="v0.1.0"

# To install only the core components:
kubectl apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/${VERSION}/manifest.yaml

# To install the extensions components:
kubectl apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/${VERSION}/extensions.yaml
