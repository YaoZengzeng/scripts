#!/bin/bash

kubectl exec "$1" -c istio-proxy -- curl -XPOST 127.0.0.1:15000/logging?level=trace
