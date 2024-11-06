#!/bin/bash

# install sleep first

NAMESPACE="${1:-default}"

kubectl exec deploy/sleep -n "$NAMESPACE" -- sh -c "curl -s http://productpage:9080/productpage | grep reviews-v.-"
