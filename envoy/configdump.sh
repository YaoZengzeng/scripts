#!/bin/bash

NAMESPACE="${2:-default}"

if [ "$IPV6" = "true" ]; then
	kubectl exec "$1" -n "$NAMESPACE" -- curl [::]:15000/config_dump > envoy.dump
else
	kubectl exec "$1" -n "$NAMESPACE" -- curl 127.0.0.1:15000/config_dump > envoy.dump
fi
