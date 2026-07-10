#!/bin/bash

# Install Kthena with Session Boost enabled.
# Thin wrapper around install_chart.sh that turns on session-aware boosting and
# applies the tuned parameters below.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/install_chart.sh" \
    --session-boost \
    --session-boost-header X-Correlation-ID \
    --session-boost-max-sessions 4096 \
    --session-boost-inflight-per-pod 8 \
    --session-boost-grace-period 50ms \
    --session-boost-timeout 15s \
    "$@"
