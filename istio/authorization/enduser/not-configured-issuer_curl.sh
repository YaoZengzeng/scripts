#!/bin/sh

WRONG_ISSUER=$(< not-configured-issuer.jwt); \
curl -H "Host: webapp.istioinaction.io" \
     -H "Authorization: Bearer $WRONG_ISSUER" \
     -sSL 10.0.2.15:32721/api/catalog
