#!/bin/bash

NAMESPACE="${1:-ollama}"

helm repo add ollama-helm https://otwld.github.io/ollama-helm/

helm repo update

kubectl create ns $NAMESPACE

helm install ollama ollama-helm/ollama --namespace $NAMESPACE --set podLabels.app=$NAMESPACE
