#!/bin/bash

kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ambient
nodes:
- role: control-plane
EOF

kubectl cluster-info --context kind-ambient

