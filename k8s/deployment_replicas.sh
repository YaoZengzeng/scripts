#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Usage: $0 <namespace> <deployment> <replicas>"
  exit 1
fi

NAMESPACE=$1
DEPLOYMENT=$2
REPLICAS=$3

kubectl -n "$NAMESPACE" scale deployment "$DEPLOYMENT" --replicas="$REPLICAS"