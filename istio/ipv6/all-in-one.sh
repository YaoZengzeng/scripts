#!/bin/bash

kubectl create namespace dual-stack
kubectl create namespace ipv4
kubectl create namespace ipv6

kubectl apply --namespace ipv4 -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/tcp-echo/tcp-echo-ipv4.yaml
kubectl apply --namespace dual-stack -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/tcp-echo/tcp-echo-dual-stack.yaml
kubectl apply --namespace ipv6 -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/tcp-echo/tcp-echo-ipv6.yaml
