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
export API_TOKEN="${API_TOKEN:-}"
export SESSION_ID="${SESSION_ID:085dab95-06df-44d6-8b2e-2c7a411b4d58}"

python3 << 'EOF'
import json
import os
import sys

from agentcube import CodeInterpreterClient

NAMESPACE            = os.environ.get("AGENTCUBE_NAMESPACE", "agentcube")
WORKLOAD_MANAGER_URL = os.environ.get("WORKLOAD_MANAGER_URL", "http://localhost:8080")
ROUTER_URL           = os.environ.get("ROUTER_URL",           "http://localhost:8081")
API_TOKEN            = os.environ.get("API_TOKEN",            None)
SESSION_ID           = os.environ.get("SESSION_ID",           None) or None

CI_NAME = "e2e-code-interpreter"

PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"

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
        auth_token=API_TOKEN,
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
        with make_client() as client:
            assert client.session_id, "Session ID should be created automatically"
            print(f"  session_id = {client.session_id}")

            # Upload script
            print("  Uploading fibonacci.py …")
            client.write_file(fibonacci_script, "fibonacci.py")

            # Execute script
            print("  Executing fibonacci.py …")
            exec_result = client.run_code("python", fibonacci_script)
            print(f"  exec_result = {exec_result!r}")
            assert "Fibonacci sequence generated" in exec_result, (
                f"Expected success message, got: {exec_result!r}"
            )

            # Download result
            print("  Downloading output.json …")
            client.download_file("output.json", tmp_path)

            with open(tmp_path) as f:
                data = json.load(f)
            print(f"  JSON = {json.dumps(data)}")

            assert data["fibonacci_sequence"] == expected_fib, (
                f"Fibonacci mismatch: expected {expected_fib}, got {data['fibonacci_sequence']}"
            )
            assert data["length"] == len(expected_fib), (
                f"Length mismatch: expected {len(expected_fib)}, got {data['length']}"
            )
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
            print(f"  Cleaned up {tmp_path}")

    print(f"  [{PASS}] session reuse: file-based Fibonacci JSON workflow")
except Exception as e:
    print(f"  [{FAIL}] session reuse: file-based Fibonacci JSON workflow: {e}")
    sys.exit(1)
EOF
