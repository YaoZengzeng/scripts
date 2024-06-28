#!/bin/bash

if [ "$#" -eq 1 ]; then
	kubectl label namespace "$1" istio-injection=enabled --overwrite
else
	kubectl label namespace "$1" istio-injection-
fi
