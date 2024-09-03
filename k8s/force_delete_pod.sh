#!/bin/bash

NAME="$1"

NAMESPACE="${2:-default}"

kubectl delete pods $NAME -n $NAMESPACE --grace-period=0 --force
