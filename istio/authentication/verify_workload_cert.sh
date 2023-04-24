#!/bin/sh

# verify the cert is signed by the Istio CA
# 1. exec to the pod
# 2. execute openssl in the pod
kubectl exec -it \
	deploy/webapp -c istio-proxy -- /bin/bash

openssl verify -CAfile /var/run/secrets/istio/root-cert.pem \
	<(openssl s_client -connect \
	catalog.default.svc.cluster.local:80 -showcerts 2>/dev/null)
