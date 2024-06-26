#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/sleep/sleep.yaml

