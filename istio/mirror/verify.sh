#!/bin/bash

NAMESPACE="${1:-default}"

kubectl exec -n $NAMESPACE deploy/sleep -c sleep -- curl -sS http://httpbin:8000/headers
