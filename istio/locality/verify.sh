#!/bin/bash

for in in {1..20}; do \
	kubectl exec deploy/simple-web -- curl -s http://simple-backend  \
| jq ".body"; printf "\n"; done
