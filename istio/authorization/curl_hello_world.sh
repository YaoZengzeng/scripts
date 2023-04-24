#!/bin/sh

kubectl -n default exec deploy/sleep -c sleep -- \
	curl -sSL webapp.default/hello/world
