#!/bin/bash

NODE="${1:-kmesh-testing-control-plane}"

kubectl label node $NODE node.kubernetes.io/exclude-from-external-load-balancers-
