#!/bin/sh

curl -H "Host: simple-sni-1.istioinaction.io" \
	https://simple-sni-1.istioinaction.io:31413/ \
	--cacert simple-sni-1/2_intermediate/certs/ca-chain.cert.pem \
	--resolve simple-sni-1.istioinaction.io:31413:10.0.2.15
