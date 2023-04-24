#!/bin/bash

for in in {1..10}; do \
	curl -s -H "Host: simple-web.istioinaction.io" 10.0.2.15:32721 \
	| jq ".upstream_calls[0].body"; printf "\n"; done
