#!/bin/bash

# Simple code execution with auto session creation.
# Requires port-forwards to be active (see portforward.sh):
#   workloadmanager -> localhost:8080
#   agentcube-router -> localhost:8081
#
# Usage:
#   AGENTCUBE_NAMESPACE=agentcube ./run_simple.sh
#   AGENTCUBE_NAMESPACE=default   API_TOKEN=xxx ./run_simple.sh
#
# The session ID created during the run is printed on a line like:
#   SESSION_ID=<id>
# so that run_session_reuse.sh can reuse it:
#   SESSION_ID=$(./run_simple.sh | grep '^SESSION_ID=' | cut -d= -f2)

export AGENTCUBE_NAMESPACE="${AGENTCUBE_NAMESPACE:-agentcube}"
export WORKLOAD_MANAGER_URL="${WORKLOAD_MANAGER_URL:-http://localhost:8080}"
export ROUTER_URL="${ROUTER_URL:-http://localhost:8081}"
export API_TOKEN="${API_TOKEN:-}"

python3 << 'EOF'
import os
import sys

from agentcube import CodeInterpreterClient

NAMESPACE            = os.environ.get("AGENTCUBE_NAMESPACE", "agentcube")
WORKLOAD_MANAGER_URL = os.environ.get("WORKLOAD_MANAGER_URL", "http://localhost:8080")
ROUTER_URL           = os.environ.get("ROUTER_URL",           "http://localhost:8081")
API_TOKEN            = os.environ.get("API_TOKEN",            None)

CI_NAME = "e2e-code-interpreter"

PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"

print(f"\nAgentCube CodeInterpreter – Simple Execution")
print(f"  namespace           = {NAMESPACE}")
print(f"  workload_manager    = {WORKLOAD_MANAGER_URL}")
print(f"  router              = {ROUTER_URL}")
print(f"  code-interpreter CR = {CI_NAME}")

def make_client():
    return CodeInterpreterClient(
        name=CI_NAME,
        namespace=NAMESPACE,
        workload_manager_url=WORKLOAD_MANAGER_URL,
        router_url=ROUTER_URL,
        auth_token=API_TOKEN,
        verbose=True,
    )

# ── Simple code execution with auto session creation ─────────────────────────
print(f"\n{'='*60}")
print("Running: simple code execution (auto session)")
print('='*60)

try:
    # Do NOT use `with` here – we want the session to stay alive so that
    # run_session_reuse.sh can reuse it via SESSION_ID.
    client = make_client()
    assert client.session_id, "Session ID should be created automatically"
    print(f"  session_id = {client.session_id}")

    result = client.run_code("python", "print(1+1)")
    print(f"  result = {result!r}")
    assert "2" in result.strip(), f"Expected '2' in output, got: {result!r}"

    # Emit session ID so callers can capture it
    print(f"SESSION_ID={client.session_id}")

    print(f"  [{PASS}] simple code execution (auto session)")
except Exception as e:
    print(f"  [{FAIL}] simple code execution (auto session): {e}")
    sys.exit(1)
EOF
