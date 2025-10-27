#!/bin/bash

SVC="$1"
PORT="$2"
NAMESPACE="${3:-default}"

if [ -z "$SVC" ] || [ -z "$PORT" ]; then
    echo "Usage: $0 <service-name> <port> [namespace]"
    exit 1
fi

echo "Starting port-forward: $SVC:$PORT (namespace: $NAMESPACE)"
echo "Press Ctrl+C to stop"
echo "---"

# Trap SIGINT and SIGTERM signals for graceful shutdown
STOP=false
trap 'STOP=true; echo ""; echo "Stopping port-forward..."; exit 0' SIGINT SIGTERM

RETRY_COUNT=0
MAX_RETRIES=999999  # Nearly infinite retries

while [ "$STOP" = false ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    if [ $RETRY_COUNT -gt 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Reconnecting (attempt $RETRY_COUNT)..."
        # Wait 2 seconds before retrying, giving k8s time to reschedule pods
        sleep 2
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Connecting..."
    fi
    
    # Execute port-forward and capture exit status
    kubectl port-forward --address 0.0.0.0 svc/"$SVC" "$PORT":"$PORT" -n "$NAMESPACE" 2>&1
    EXIT_CODE=$?
    
    # If user stopped manually (Ctrl+C), don't retry
    if [ "$STOP" = true ]; then
        break
    fi
    
    # Connection lost, prepare to retry
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Connection lost (exit code: $EXIT_CODE)"
    
    # Check if service still exists
    if ! kubectl get svc "$SVC" -n "$NAMESPACE" &>/dev/null; then
        echo "[ERROR] Service $SVC does not exist in namespace $NAMESPACE"
        exit 1
    fi
    
    # Check if there are available pods
    POD_COUNT=$(kubectl get endpoints "$SVC" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
    if [ "$POD_COUNT" -eq 0 ]; then
        echo "[WARNING] Service $SVC has no available pod endpoints, waiting..."
        sleep 5
        continue
    fi
done

echo "Port-forward stopped"
