#!/bin/sh

kubectl apply -f coolstore-gw-tls.yaml
kubectl apply -f coolstore-vs.yaml
bash webapp-credential.sh
