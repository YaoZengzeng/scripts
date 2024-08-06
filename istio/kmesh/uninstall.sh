#!/bin/bash

helm uninstall kmesh -n kmesh-system
kubectl delete ns kmesh-system
