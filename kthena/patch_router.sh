#!/bin/bash

# Use kubectl set env for idempotent env var updates (avoids duplicates on re-run)
kubectl -n kthena-system set env deployment/kthena-router \
  ENABLE_SESSION_BOOST=true \
  SESSION_BOOST_HEADER=X-Correlation-ID \
  SESSION_BOOST_TTL=60s \
  SESSION_BOOST_GRACE_PERIOD=50ms \
  SESSION_BOOST_POLL_INTERVAL=100ms \
  SESSION_BOOST_INFLIGHT_PER_POD=8 \
  SESSION_BOOST_WAIT_PROMOTION_ENABLED=true \
  SESSION_BOOST_MAX_WAIT=15s \
  METRICS_SCRAPE_INTERVAL=50ms

# Patch image and imagePullPolicy separately
kubectl -n kthena-system patch deployment kthena-router --type=json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "ghcr.io/yaozengzeng/kthena-router:latest"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "Always"}
]'
