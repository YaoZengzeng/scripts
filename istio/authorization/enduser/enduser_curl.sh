#!/bin/sh

USER_TOKEN=$(< user.jwt); \
curl -H "Host: webapp.istioinaction.io" \
     -H "Authorization: Bearer $USER_TOKEN" \
     -sSl -o /dev/null -w "%{http_code}" 10.0.2.15:32721/api/catalog
