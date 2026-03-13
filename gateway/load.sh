#!/bin/bash
#
# Usage: ./load.sh [model] [rate] [duration]
#
#   model    - Model name to request (default: deepseek-ai/DeepSeek-R1-Distill-Qwen-7B)
#   rate     - Requests per second (default: 10)
#   duration - How long to run in seconds, 0 = run forever (default: 0)
#
# Environment:
#   HOST - Gateway host:port (default: 127.0.0.1:80)

MODEL="${1:-"deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"}"
RATE="${2:-10}"
DURATION="${3:-0}"

HOST="${HOST:-127.0.0.1:80}"

echo "Load test starting:"
echo "  Host     : $HOST"
echo "  Model    : $MODEL"
echo "  Rate     : $RATE req/s  (parallel per second)"
echo "  Duration : $([ "$DURATION" -eq 0 ] && echo 'unlimited' || echo "${DURATION}s")"
echo ""

START=$(date +%s)
TOTAL=0

send_request() {
    local seq="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        http://$HOST/v1/completions \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"San Francisco is a\",
            \"temperature\": 0
        }")
    printf "[%s] Request #%-4d  HTTP %s\n" "$timestamp" "$seq" "$status"
}

while true; do
    if [ "$DURATION" -gt 0 ]; then
        NOW=$(date +%s)
        if [ $(( NOW - START )) -ge "$DURATION" ]; then
            wait
            echo ""
            echo "Duration reached. Total requests sent: $TOTAL"
            break
        fi
    fi

    # Fire $RATE requests in parallel, then wait 1 second for next batch
    for (( i = 0; i < RATE; i++ )); do
        TOTAL=$(( TOTAL + 1 ))
        send_request "$TOTAL" &
    done

    sleep 1
done
