#!/bin/bash

# Session boost is now configured at install time via install_chart.sh
# (--session-boost and related flags, mapped to
# networking.kthenaRouter.sessionBoost.*). Keep this script focused on the
# non-session-boost overrides only.

# Use kubectl set env for idempotent env var updates (avoids duplicates on re-run)
kubectl -n kthena-system set env deployment/kthena-router \
  METRICS_SCRAPE_INTERVAL=50ms

# Patch image and imagePullPolicy separately
kubectl -n kthena-system patch deployment kthena-router --type=json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "ghcr.io/yaozengzeng/kthena-router:latest"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "Always"}
]'
