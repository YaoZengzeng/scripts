#!/bin/sh

kubectl -n default exec deploy/sleep -c sleep -- \
	curl -s webapp.default/api/catalog
