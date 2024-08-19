#!/bin/bash

SVC="$1"
PORT="$2"
NAMESPACE="${3:-default}"

kubectl port-forward --address 0.0.0.0 svc/"$SVC" "$PORT":"$PORT" -n "$NAMESPACE"
