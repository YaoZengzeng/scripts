#!/bin/bash

# Session reuse and complex operations (file-based Fibonacci workflow).
# Requires port-forwards to be active (see portforward.sh):
#   workloadmanager -> localhost:8080
#   agentcube-router -> localhost:8081
#
# Usage (reusing the session created by run_simple.sh):
#   SESSION_ID=$(./run_simple.sh | grep '^SESSION_ID=' | cut -d= -f2)
#   SESSION_ID=$SESSION_ID ./run_session_reuse.sh
#
# Or standalone (a fresh session will be created automatically):
#   AGENTCUBE_NAMESPACE=agentcube ./run_session_reuse.sh

export AGENTCUBE_NAMESPACE="${AGENTCUBE_NAMESPACE:-agentcube}"
export WORKLOAD_MANAGER_URL="${WORKLOAD_MANAGER_URL:-http://localhost:8080}"
export ROUTER_URL="${ROUTER_URL:-http://localhost:8081}"
export SESSION_ID="${SESSION_ID:-91913ea1-f839-49cc-8e50-d306e7e9df53}"

python3 << 'EOF'
import json
import os
import sys
import time

from agentcube import CodeInterpreterClient

NAMESPACE            = os.environ.get("AGENTCUBE_NAMESPACE", "agentcube")
WORKLOAD_MANAGER_URL = os.environ.get("WORKLOAD_MANAGER_URL", "http://localhost:8080")
ROUTER_URL           = os.environ.get("ROUTER_URL",           "http://localhost:8081")
SESSION_ID           = os.environ.get("SESSION_ID",           None) or None

CI_NAME = "e2e-code-interpreter"

print(f"\nAgentCube CodeInterpreter – Session Reuse & Complex Operations")
print(f"  namespace           = {NAMESPACE}")
print(f"  workload_manager    = {WORKLOAD_MANAGER_URL}")
print(f"  router              = {ROUTER_URL}")
print(f"  code-interpreter CR = {CI_NAME}")
if SESSION_ID:
    print(f"  session_id (reused) = {SESSION_ID}")
else:
    print(f"  session_id          = (will be created automatically)")

def make_client():
    return CodeInterpreterClient(
        name=CI_NAME,
        namespace=NAMESPACE,
        workload_manager_url=WORKLOAD_MANAGER_URL,
        router_url=ROUTER_URL,
        session_id=SESSION_ID,
        verbose=True,
    )

# ── Session reuse: file-based Fibonacci workflow ──────────────────────────────
fibonacci_script = """\
import json

def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

fib_sequence = [fibonacci(i) for i in range(10)]
result = {"fibonacci_sequence": fib_sequence, "length": len(fib_sequence)}

with open("output.json", "w") as f:
    json.dump(result, f, indent=2)

print("Fibonacci sequence generated and saved to output.json")
"""
expected_fib = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
tmp_path = "/tmp/test_output.json"

print(f"\n{'='*60}")
print("Running: session reuse – file-based Fibonacci JSON workflow")
print('='*60)

try:
    try:
        # Do NOT use `with` here – we want the session to stay alive
        client = make_client()
        if not client.session_id:
            print("  Error: Session ID not found.")
            sys.exit(1)
        
        print(f"  Connected to session: {client.session_id}")
        time.sleep(1)

        # Upload script
        print("  Uploading fibonacci.py workflow script...")
        client.write_file(fibonacci_script, "fibonacci.py")
        time.sleep(1.5)

        # Execute script
        print("  Executing fibonacci.py in remote environment...")
        exec_result = client.run_code("python", fibonacci_script)
        print(f"  Execution output: {exec_result.strip()}")
        time.sleep(1.5)

        # Download result
        print("  Retrieving generated output.json...")
        client.download_file("output.json", tmp_path)
        time.sleep(1)

        with open(tmp_path) as f:
            data = json.load(f)
        print(f"  Successfully processed data: {json.dumps(data)}")
        time.sleep(1)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
            print(f"  Cleaned up {tmp_path}")

    print("\n[SUCCESS] Fibonacci workflow completed.")
except Exception as e:
    print(f"\n  Error during workflow: {e}")
    sys.exit(1)
EOF
