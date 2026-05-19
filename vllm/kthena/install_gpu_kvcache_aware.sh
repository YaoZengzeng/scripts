#!/bin/bash

kubectl apply -f ./gpu-kvcache-aware.yaml

kubectl apply -f ./modelroute.yaml

kubectl apply -f ./modelserver.yaml
