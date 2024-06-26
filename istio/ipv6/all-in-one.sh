#!/bin/bash

kubectl create namespace dual-stack
kubectl create namespace ipv6

kubectl label --overwrite namespace dual-stack istio-injection=enabled
kubectl label --overwrite namespace ipv6 istio-injection=enabled

kubectl apply --namespace dual-stack -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/tcp-echo/tcp-echo-dual-stack.yaml
 kubectl apply --namespace ipv6 -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/tcp-echo/tcp-echo-ipv6.yaml
