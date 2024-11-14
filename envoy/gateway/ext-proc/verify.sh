#!/bin/bash

# install metallb first

export GATEWAY_HOST=$(kubectl get gateway/eg -o jsonpath='{.status.addresses[0].value}')

curl -v -H "Host: www.example.com" "http://${GATEWAY_HOST}/myapp"
