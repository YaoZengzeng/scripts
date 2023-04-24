#!/bin/sh

ADMIN_TOKEN=$(< admin.jwt);
curl -H "Host: webapp.istioinaction.io" \
     -H "Authorization: Bearer $ADMIN_TOKEN" \
     -XPOST -sSl -w "%{http_code}" 10.0.2.15:32721/api/catalog/items \
     --data '{"id": 2, "name": "Shoes", "price": "84.00"}'
