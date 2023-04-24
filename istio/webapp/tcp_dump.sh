#!/bin/sh

kubectl exec deploy/webapp -c istio-proxy \
	-- sudo tcpdump -l --immediate-mode -vv -s 0 \
	'(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
