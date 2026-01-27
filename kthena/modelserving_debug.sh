#!/bin/bash

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELSERVING_YAML="${SCRIPT_DIR}/modelserving.yaml"
MODELSERVING_NAME="sample-restort"

echo "Starting ModelServing debug loop..."
echo "ModelServing YAML: ${MODELSERVING_YAML}"
echo "ModelServing Name: ${MODELSERVING_NAME}"
echo ""

iteration=1

while true; do
    echo "==================================="
    echo "Iteration #${iteration}"
    echo "==================================="
    
    # Apply the modelserving yaml
    echo "[Step 1/3] Applying ModelServing YAML..."
    kubectl apply -f "${MODELSERVING_YAML}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to apply ModelServing YAML"
        exit 1
    fi
    echo "ModelServing applied successfully"
    echo ""
    
    # Monitor pod count in default namespace (checking every 1s for 60s)
    echo "[Step 2/3] Monitoring pod count in default namespace (checking every 1s for 60s)..."
    
    # Pick a random check number (1-60) to restart kthena-system pods
    RESTART_AT=$((RANDOM % 60 + 1))
    echo "Will restart kthena-system pods at check #${RESTART_AT}"
    echo ""
    
    success=false
    for check in {1..60}; do
        # Restart all pods in kthena-system namespace only at the random check
        if [ "${check}" -eq "${RESTART_AT}" ]; then
            echo "Check ${check}/60: Restarting kthena-system pods..."
            kubectl delete pods --all -n kthena-system &>/dev/null
        fi
        
        # Check pod count in default namespace
        POD_COUNT=$(kubectl get pods -n default --no-headers 2>/dev/null | wc -l)
        echo "Check ${check}/60: Pod count = ${POD_COUNT}"
        
        if [ "${POD_COUNT}" -ge 112 ]; then
            echo "✗ Pod count (${POD_COUNT}) is >= 112, breaking early to retry..."
            break
        fi
        
        # Wait 1 second before next check (skip on last iteration)
        if [ "${check}" -lt 60 ]; then
            sleep 1
        fi
    done
    echo ""
    
    # Check final result
    if [ "${POD_COUNT}" -lt 112 ]; then
        echo "✓ Success! Pod count (${POD_COUNT}) is less than 112"
        echo "Exiting debug loop after ${iteration} iteration(s)"
        break
    else
        echo "[Step 3/3] Cleaning up for retry..."
        echo "Deleting ModelServing..."
        
        # Delete the modelserving
        kubectl delete modelserving "${MODELSERVING_NAME}" 2>/dev/null
        echo "ModelServing deleted"
        echo ""
        
        # Wait for pod count to become 0
        echo "Waiting for pod count to reach 0..."
        wait_count=0
        while true; do
            POD_COUNT=$(kubectl get pods -n default --no-headers 2>/dev/null | wc -l)
            echo "Cleanup check: Pod count = ${POD_COUNT}"
            
            if [ "${POD_COUNT}" -eq 0 ]; then
                echo "✓ Pod count is 0, ready for next iteration"
                break
            fi
            
            wait_count=$((wait_count + 1))
            if [ "${wait_count}" -ge 60 ]; then
                echo "⚠ Warning: Waited 60 seconds for cleanup, proceeding anyway..."
                break
            fi
            
            sleep 1
        done
        echo ""
        
        iteration=$((iteration + 1))
    fi
done

echo ""
echo "==================================="
echo "Debug script completed successfully!"
echo "==================================="
