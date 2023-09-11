#!/bin/bash

kubectl create -f tigera-operator.yaml

kubectl create -f custom-resources.yaml

