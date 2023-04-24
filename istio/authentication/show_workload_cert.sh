#!/bin/bash

# show cert
kubectl exec deploy/webapp -c istio-proxy \
	-- openssl s_client -showcerts \
	-connect catalog.default.svc.cluster.local:80 \
	-CAfile /var/run/secrets/istio/root-cert.pem | \
	openssl x509 -in /dev/stdin -text -noout

