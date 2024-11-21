#!/bin/bash

helm uninstall eg -n envoy-gateway-system

kubectl delete ns envoy-gateway-system
