#!/bin/bash

# Skip if a gpu-operator release is already installed in the namespace.
if helm list -n gpu-operator -q 2>/dev/null | grep -q '^gpu-operator'; then
  echo "GPU Operator already installed in namespace 'gpu-operator', skipping."
  exit 0
fi

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
  && helm repo update

helm install --wait --generate-name \
  -n gpu-operator --create-namespace \
  nvidia/gpu-operator \
  --set driver.enabled=false \
  --set toolkit.enabled=false
