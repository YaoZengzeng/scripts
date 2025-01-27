#!/bin/bash

NAMESPACE="${1:-ollama}"

LOCAL_PORT=11434

export POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=ollama,app.kubernetes.io/instance=ollama" -o jsonpath="{.items[0].metadata.name}")

export CONTAINER_PORT=$(kubectl get pod --namespace $NAMESPACE $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")

echo "Visit http://127.0.0.1:$LOCAL_PORT to use your application"

kubectl --namespace $NAMESPACE port-forward $POD_NAME $LOCAL_PORT:$CONTAINER_PORT
