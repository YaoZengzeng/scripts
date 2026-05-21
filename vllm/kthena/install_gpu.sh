#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/gpu.yaml"

kubectl apply -f "$SCRIPT_DIR/modelroute.yaml"

kubectl apply -f "$SCRIPT_DIR/modelserver.yaml"
