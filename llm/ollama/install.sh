#!/bin/bash

helm repo add ollama-helm https://otwld.github.io/ollama-helm/

helm repo update

kubectl create ns ollama

helm install ollama ollama-helm/ollama --namespace ollama
