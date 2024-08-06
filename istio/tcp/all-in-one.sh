#!/bin/bash

NAMESPACE="${1:-default}"

kubectl apply -f ./tcp-echo-services.yaml -n "$NAMESPACE"
