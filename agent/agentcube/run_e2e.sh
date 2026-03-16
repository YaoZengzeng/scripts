#!/bin/bash

# E2E tests for CodeInterpreter using the agentcube Python SDK.
# Requires port-forwards to be active (see portforward.sh):
#   workloadmanager -> localhost:8080
#   agentcube-router -> localhost:8081
#
# Usage:
#   AGENTCUBE_NAMESPACE=agentcube ./run_e2e.sh
#   AGENTCUBE_NAMESPACE=default   API_TOKEN=xxx ./run_e2e.sh

export AGENTCUBE_NAMESPACE="${AGENTCUBE_NAMESPACE:-agentcube}"
export WORKLOAD_MANAGER_URL="${WORKLOAD_MANAGER_URL:-http://localhost:8080}"
export ROUTER_URL="${ROUTER_URL:-http://localhost:8081}"
export API_TOKEN="${API_TOKEN:-}"

python3 << 'EOF'
import json
import os
import sys

from agentcube import CodeInterpreterClient
from agentcube.exceptions import CommandExecutionError

NAMESPACE            = os.environ.get("AGENTCUBE_NAMESPACE", "agentcube")
WORKLOAD_MANAGER_URL = os.environ.get("WORKLOAD_MANAGER_URL", "http://localhost:8080")
ROUTER_URL           = os.environ.get("ROUTER_URL",           "http://localhost:8081")
API_TOKEN            = os.environ.get("API_TOKEN",            None)

CI_NAME = "e2e-code-interpreter"

PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"

results = []

def make_client():
    return CodeInterpreterClient(
        name=CI_NAME,
        namespace=NAMESPACE,
        workload_manager_url=WORKLOAD_MANAGER_URL,
        router_url=ROUTER_URL,
        auth_token=API_TOKEN,
        verbose=True,
    )

def run_test(name, fn):
    print(f"\n{'='*60}")
    print(f"Running: {name}")
    print('='*60)
    try:
        fn()
        print(f"  [{PASS}] {name}")
        results.append((name, True, None))
    except Exception as e:
        print(f"  [{FAIL}] {name}: {e}")
        results.append((name, False, str(e)))


# ── Case 1: Simple code execution with auto session creation ──────────────────
def case1_simple_execution():
    """POST run without explicit session → HTTP 200, stdout '2', session-id header present."""
    with make_client() as client:
        assert client.session_id, "Session ID should be created automatically"
        print(f"  session_id = {client.session_id}")

        result = client.run_code("python", "print(1+1)")
        print(f"  result = {result!r}")
        assert "2" in result.strip(), f"Expected '2' in output, got: {result!r}"


# ── Case 2: Stateless execution within one session ────────────────────────────
def case2_stateless_session():
    """Reuse one session; second call referencing a var from the first must raise NameError."""
    with make_client() as client:
        assert client.session_id, "Session ID should be created automatically"
        print(f"  session_id = {client.session_id}")

        # First call – define a variable
        result1 = client.run_code("python", "x = 10\nprint('defined')")
        print(f"  result1 = {result1!r}")
        assert "defined" in result1.strip(), f"Expected 'defined', got: {result1!r}"

        # Second call – reference the variable; must fail (stateless)
        try:
            client.run_code("python", "print(x)")
            raise AssertionError("Expected CommandExecutionError (NameError) but call succeeded")
        except CommandExecutionError as exc:
            stderr = exc.stderr or ""
            print(f"  stderr = {stderr!r}")
            assert "NameError" in stderr or "name 'x' is not defined" in stderr, (
                f"Expected NameError in stderr, got: {stderr!r}"
            )


# ── Case 3: File-based Fibonacci workflow ─────────────────────────────────────
def case3_fibonacci_json():
    """Upload script → execute → download output.json → verify Fibonacci sequence."""
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


# ── Run all cases ─────────────────────────────────────────────────────────────
print(f"\nAgentCube CodeInterpreter E2E Tests")
print(f"  namespace           = {NAMESPACE}")
print(f"  workload_manager    = {WORKLOAD_MANAGER_URL}")
print(f"  router              = {ROUTER_URL}")
print(f"  code-interpreter CR = {CI_NAME}")

run_test("Case1: simple code execution (auto session)", case1_simple_execution)
run_test("Case2: stateless execution within a session", case2_stateless_session)
run_test("Case3: file-based Fibonacci JSON workflow",   case3_fibonacci_json)

# ── Summary ───────────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print("Results:")
passed = sum(1 for _, ok, _ in results if ok)
for name, ok, err in results:
    status = PASS if ok else FAIL
    suffix = f": {err}" if err else ""
    print(f"  [{status}] {name}{suffix}")

print(f"\n{passed}/{len(results)} tests passed")
print('='*60)

if passed < len(results):
    sys.exit(1)
EOF
