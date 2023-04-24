#!/bin/sh

curl -H "Host: simple-sni-2.istioinaction.io" \
	https://simple-sni-2.istioinaction.io:31413/ \
	--cacert simple-sni-2/2_intermediate/certs/ca-chain.cert.pem \
	--resolve simple-sni-2.istioinaction.io:31413:10.0.2.15
