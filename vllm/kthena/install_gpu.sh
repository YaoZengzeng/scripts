#!/bin/bash

kubectl apply -f ./gpu.yaml

kubectl apply -f ./modelroute.yaml

kubectl apply -f ./modelserver.yaml
