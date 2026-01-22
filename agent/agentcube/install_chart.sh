#!/bin/bash

# Install agent-sandbox CRDs and controller
kubectl apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/v0.1.0/manifest.yaml
kubectl apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/v0.1.0/extensions.yaml

kubectl create namespace agentcube

kubectl -n agentcube create deployment redis --image=redis:7-alpine --port=6379
kubectl -n agentcube expose deployment redis --port=6379 --target-port=6379

# Wait for Redis to be ready
kubectl -n agentcube rollout status deployment/redis

cd /root/agentcube

helm install agentcube ./manifests/charts/base \
    --namespace agentcube \
    --create-namespace \
    --set redis.addr="redis.agentcube.svc.cluster.local:6379" \
    --set redis.password="''''" \
    --set router.rbac.create=true \
    --set router.serviceAccountName="agentcube-router"
