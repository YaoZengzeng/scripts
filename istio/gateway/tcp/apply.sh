#!/bin/sh

kubectl apply -f echo.yaml
kubectl apply -f echo-vs.yaml
kubectl apply -f gateway-tcp.yaml
