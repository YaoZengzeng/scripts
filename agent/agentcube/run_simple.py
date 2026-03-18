#!/usr/bin/env python3
import os
import sys
import time

from agentcube import CodeInterpreterClient

# Simple code execution with auto session creation.
# Requires port-forwards to be active (see portforward.sh):
#   workloadmanager -> localhost:8080
#   agentcube-router -> localhost:8081
#
# Usage:
#   NAMESPACE=default python3 run_simple.py
#
# The session ID created during the run is printed on a line like:
#   SESSION_ID=<id>
# so that run_session_reuse.py can reuse it:
#   SESSION_ID=$(python3 run_simple.py | grep '^SESSION_ID=' | cut -d= -f2) python3 run_session_reuse.py

NAMESPACE            = os.environ.get("NAMESPACE", "default")
WORKLOAD_MANAGER_URL = os.environ.get("WORKLOAD_MANAGER_URL", "http://localhost:8080")
ROUTER_URL           = os.environ.get("ROUTER_URL",           "http://localhost:8081")

CI_NAME = "my-interpreter"

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
        verbose=True,
    )

# ── Simple code execution with auto session creation ─────────────────────────
print(f"\n{'='*60}")
print("Running: simple code execution (auto session)")
print('='*60)

try:
    # Initialize the client
    print("\n  Initializing CodeInterpreter client...")
    time.sleep(1)
    client = make_client()
    
    if not client.session_id:
        print("  Error: Failed to create session.")
        sys.exit(1)
        
    print(f"  Session established: {client.session_id}")
    time.sleep(1.5)

    print(f"  Executing code: print(1+1) ...")
    result = client.run_code("python", "print(1+1)")
    time.sleep(1)
    print(f"  Output result: {result.strip()}")

    # Emit session ID so callers can capture it
    print(f"\nSESSION_ID={client.session_id}")
    print("\n[SUCCESS] Simple execution completed.")
except Exception as e:
    print(f"\n  Error during execution: {e}")
    sys.exit(1)
