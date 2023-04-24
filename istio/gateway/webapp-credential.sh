#!/bin/sh

kubectl create -n istio-system secret tls webapp-credential \
	--key certs/3_application/private/webapp.istioinaction.io.key.pem \
	--cert certs/3_application/certs/webapp.istioinaction.io.cert.pem
