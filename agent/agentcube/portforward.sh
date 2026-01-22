#!/bin/bash

# This script forwards agentcube services to localhost
# - agentcube-router: localhost:8081
# - workloadmanager: localhost:8080

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORWARD_SCRIPT="$SCRIPT_DIR/../../portforward/forward.sh"

# Check if forward.sh exists
if [ ! -f "$FORWARD_SCRIPT" ]; then
    echo "Error: $FORWARD_SCRIPT not found"
    exit 1
fi

# Make sure it's executable
chmod +x "$FORWARD_SCRIPT"

# Namespace for the services (adjust if needed)
NAMESPACE="${NAMESPACE:-agentcube}"

# Function to start port-forward in background
start_forward() {
    local service=$1
    local local_port=$2
    local service_port=$3
    
    echo "Starting port-forward for $service on localhost:$local_port"
    "$FORWARD_SCRIPT" "$service" "$local_port" "$service_port" "$NAMESPACE" &
    local pid=$!
    echo "  PID: $pid"
    return $pid
}

# Trap SIGINT and SIGTERM to kill background processes
trap 'echo ""; echo "Stopping all port-forwards..."; kill $(jobs -p) 2>/dev/null; exit 0' SIGINT SIGTERM

echo "=================================="
echo "AgentCube Port Forwarding"
echo "=================================="
echo "Namespace: $NAMESPACE"
echo ""

# Start port-forwards for both services
# Both services use port 8080
start_forward "agentcube-router" 8081 8080
ROUTER_PID=$!

start_forward "workloadmanager" 8080 8080
WORKLOAD_PID=$!

echo ""
echo "=================================="
echo "Port-forwards started:"
echo "  agentcube-router: localhost:8081"
echo "  workloadmanager:  localhost:8080"
echo "=================================="
echo "Press Ctrl+C to stop all port-forwards"
echo ""

# Wait for all background jobs
wait
