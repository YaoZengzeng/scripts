#!/bin/bash

kubectl -n kthena-system patch deployment kthena-router --type=json -p '[
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "ENABLE_SESSION_BOOST", "value": "true"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "SESSION_BOOST_HEADER", "value": "X-Correlation-ID"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "SESSION_BOOST_TTL", "value": "60s"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "SESSION_BOOST_GRACE_PERIOD", "value": "50ms"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "SESSION_BOOST_POLL_INTERVAL", "value": "100ms"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "SESSION_BOOST_INFLIGHT_PER_POD", "value": "8"}},
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "ghcr.io/yaozengzeng/kthena-router:latest"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "Always"}
]'
