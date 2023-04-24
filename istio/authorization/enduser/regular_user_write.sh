#!/bin/sh

USER_TOKEN=$(< user.jwt);
curl -H "Host: webapp.istioinaction.io" \
     -H "Authorization: Bearer $USER_TOKEN" \
     -XPOST 10.0.2.15:32721/api/catalog \
     --data '{"id": 2, "name": "Shoes", "price": "84.00"}'

