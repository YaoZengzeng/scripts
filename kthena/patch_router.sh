#!/bin/bash

kubectl -n kthena-system patch deployment kthena-router --type=json -p '[
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "ENABLE_FAIRNESS_SCHEDULING", "value": "true"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "FAIRNESS_MAX_QPS", "value": "10"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "FAIRNESS_MAX_CONCURRENT", "value": "0"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "FAIRNESS_SESSION_BOOST_ENABLED", "value": "true"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "FAIRNESS_SESSION_BOOST_TTL", "value": "60s"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "FAIRNESS_INFLIGHT_PER_POD", "value": "8"}},
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "ghcr.io/yaozengzeng/kthena-router:latest"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "Always"}
]'
