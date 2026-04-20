#!/bin/bash

export HF_TOKEN=<your-huggingface-token>
export HF_TOKEN_NAME=${HF_TOKEN_NAME:-llm-d-hf-token}
export NAMESPACE=${NAMESPACE:-llm-d}

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic ${HF_TOKEN_NAME} \
    --from-literal="HF_TOKEN=${HF_TOKEN}" \
    --namespace "${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -
