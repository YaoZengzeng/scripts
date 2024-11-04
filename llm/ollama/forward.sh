#!/bin/bash

LOCAL_PORT=11434

export POD_NAME=$(kubectl get pods --namespace ollama -l "app.kubernetes.io/name=ollama,app.kubernetes.io/instance=ollama" -o jsonpath="{.items[0].metadata.name}")

export CONTAINER_PORT=$(kubectl get pod --namespace ollama $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")

echo "Visit http://127.0.0.1:$LOCAL_PORT to use your application"

kubectl --namespace ollama port-forward $POD_NAME $LOCAL_PORT:$CONTAINER_PORT
