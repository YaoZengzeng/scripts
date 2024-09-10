#!/bin/bash

NAMESPACE="${1:-default}"

kubectl exec deploy/sleep -n $NAMESPACE -c sleep -- curl -sS http://httpbin:8000/headers
