#!/bin/sh

# with internal headers for v2, without internal headers for v1
curl http://10.0.2.15:32721/api/catalog -H "Host: webapp.istioinaction.io" -H "x-istio-cohort: internal"
