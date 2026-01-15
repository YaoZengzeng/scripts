#!/bin/bash

POD="${1:-default}"

kubectl exec $POD -- curl 127.0.0.1:8000/v1/models
