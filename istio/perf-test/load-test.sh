#!/bin/bash

kubectl exec deploy/loadclient -- /usr/bin/fortio load -qps -1 -c 1 -t 10s -payload-size 1000 --timeout 120s  http://istio-ingressgateway.istio-system
