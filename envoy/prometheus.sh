#!/bin/bash

NAMESPACE="${2:-default}"

kubectl exec "$1"  -n "$NAMESPACE" -- curl 127.0.0.1:15000/stats/prometheus
