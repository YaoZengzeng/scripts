#!/bin/bash

TCP_HOST="10.96.182.181"
TCP_PORT="9000"

for i in {1..20}; do \
	kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" \
	-c sleep -- sh -c "(date; sleep 1) | nc $TCP_HOST $TCP_PORT"; \
done
