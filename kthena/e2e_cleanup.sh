#!/bin/bash

helm uninstall kthena -n dev

kubectl delete ns $1

# Kill any process listening on port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

