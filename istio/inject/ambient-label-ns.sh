#!/bin/bash

if [ "$#" -eq 1 ]; then
        kubectl label namespace "$1" istio.io/dataplane-mode=ambient --overwrite
else
        kubectl label namespace "$1" istio.io/dataplane-mode-
fi
