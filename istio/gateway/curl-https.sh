#!/bin/bash

# https, run the following command in the directory 'worknotes/istio/gateway'
curl -v -H "Host: webapp.istioinaction.io" https://webapp.istioinaction.io:31398/api/catalog \
	--cacert certs/2_intermediate/certs/ca-chain.cert.pem \
	--resolve webapp.istioinaction.io:31398:10.0.2.15

