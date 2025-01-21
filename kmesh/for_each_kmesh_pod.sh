#!/bin/bash

# Set log of each Kmesh pods.
PODS=$(kubectl get pods -n kmesh-system -l app=kmesh -o jsonpath='{.items[*].metadata.name}')


for POD in $PODS; do
    echo $POD
    kmeshctl log $POD --set bpf:debug
done
