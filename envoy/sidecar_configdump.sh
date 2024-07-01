#!/bin/bash

kubectl exec "$1" -c istio-proxy  -- curl 127.0.0.1:15000/config_dump > envoy_sidecar.dump
