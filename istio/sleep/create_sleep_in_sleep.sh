#!/bin/bash

kubectl create ns sleep

kubectl label namespace sleep istio-injection=enabled --overwrite

kubectl apply -f sleep_in_sleep_ns.yaml
