#!/usr/bin/env bash
# Multi-Turn Conversation Benchmark Script for AIPerf
# Reference: https://github.com/ai-dynamo/aiperf/blob/main/docs/tutorials/multi-turn.md
set -euo pipefail

###############################################################################
# Configuration
###############################################################################
MODEL="${MODEL:-Qwen/Qwen3-0.6B}"
TOKENIZER="${TOKENIZER:-}"            # defaults to MODEL if empty
URL="${URL:-172.236.134.222:80}"
ENDPOINT_TYPE="${ENDPOINT_TYPE:-chat}"
STREAMING="${STREAMING:-true}"
UI="${UI:-dashboard}"
CONCURRENCY="${CONCURRENCY:-13}"
RANDOM_SEED="${RANDOM_SEED:-42}"

# Conversation control
CONVERSATION_NUM="${CONVERSATION_NUM:-40}"
TURN_MEAN="${TURN_MEAN:-10}"
TURN_STDDEV="${TURN_STDDEV:-0}"

# Turn delays (milliseconds)
TURN_DELAY_MEAN="${TURN_DELAY_MEAN:-0}"
TURN_DELAY_STDDEV="${TURN_DELAY_STDDEV:-0}"

# Token parameters
INPUT_TOKENS_MEAN="${INPUT_TOKENS_MEAN:-2000}"
INPUT_TOKENS_STDDEV="${INPUT_TOKENS_STDDEV:-}"    # empty = not set
OUTPUT_TOKENS_MEAN="${OUTPUT_TOKENS_MEAN:-150}"
OUTPUT_TOKENS_STDDEV="${OUTPUT_TOKENS_STDDEV:-}"   # empty = not set

# Request rate control (optional)
REQUEST_RATE="${REQUEST_RATE:-}"           # empty = not set
REQUEST_RATE_MODE="${REQUEST_RATE_MODE:-}" # empty = not set (e.g. poisson)

# Dataset
NUM_DATASET_ENTRIES="${NUM_DATASET_ENTRIES:-}" # empty = not set

# Retry control (optional)
MAX_RETRIES="${MAX_RETRIES:-0}"          # empty = not set
RETRY_DELAY="${RETRY_DELAY:-1}"          # empty = not set (seconds)
RETRY_MAX_DELAY="${RETRY_MAX_DELAY:-10}"  # empty = not set (seconds)

# Output
ARTIFACT_DIR="${ARTIFACT_DIR:-artifacts}"

###############################################################################
# Helpers
###############################################################################
usage() {
    cat <<EOF
Usage: $0 [options]

Runs a fixed-length multi-turn conversation benchmark.

Environment variables (override defaults):
  MODEL                Model name                          (default: Qwen/Qwen3-0.6B)
  TOKENIZER            Tokenizer (defaults to MODEL)
  URL                  Server URL                          (default: localhost:8000)
  ENDPOINT_TYPE        Endpoint type                       (default: chat)
  STREAMING            Enable streaming                    (default: true)
  UI                   UI type: dashboard|simple|none      (default: dashboard)
  CONCURRENCY          Concurrent conversations            (default: 2)
  RANDOM_SEED          Random seed for reproducibility     (default: 42)

  CONVERSATION_NUM     Number of conversation sessions     (default: 10)
  TURN_MEAN            Average turns per conversation      (default: 3)
  TURN_STDDEV          Turns standard deviation            (default: 0)

  TURN_DELAY_MEAN      Average delay between turns (ms)    (default: 0)
  TURN_DELAY_STDDEV    Delay standard deviation (ms)       (default: 0)

  INPUT_TOKENS_MEAN    Mean input tokens per turn          (default: 200)
  INPUT_TOKENS_STDDEV  Input tokens standard deviation     (default: not set)
  OUTPUT_TOKENS_MEAN   Mean output tokens per turn         (default: 150)
  OUTPUT_TOKENS_STDDEV Output tokens standard deviation    (default: not set)

  REQUEST_RATE         Conversations per second            (default: not set)
  REQUEST_RATE_MODE    Rate mode (e.g. poisson)            (default: not set)
  NUM_DATASET_ENTRIES  Unique prompts to generate          (default: not set)

  MAX_RETRIES          Max retries per request             (default: not set)
  RETRY_DELAY          Initial retry delay (seconds)       (default: not set)
  RETRY_MAX_DELAY      Max retry delay (seconds)           (default: not set)

  ARTIFACT_DIR         Output directory                    (default: artifacts)

Examples:
  $0
  MODEL=meta-llama/Llama-3-8B URL=gpu-server:8000 CONVERSATION_NUM=20 $0
  CONCURRENCY=10 CONVERSATION_NUM=50 $0
EOF
    exit 0
}

build_common_args() {
    local args=(
        --model "$MODEL"
        --endpoint-type "$ENDPOINT_TYPE"
        --url "$URL"
        --ui-type "$UI"
        --output-artifact-dir "$ARTIFACT_DIR"
        --random-seed "$RANDOM_SEED"
    )

    [[ -n "$TOKENIZER" ]] && args+=(--tokenizer "$TOKENIZER")
    [[ "$STREAMING" == "true" ]] && args+=(--streaming)
    [[ -n "$NUM_DATASET_ENTRIES" ]] && args+=(--num-dataset-entries "$NUM_DATASET_ENTRIES")

    echo "${args[@]}"
}

build_conversation_args() {
    local conv_num="${1:-$CONVERSATION_NUM}"
    local turn_mean="${2:-$TURN_MEAN}"
    local turn_stddev="${3:-$TURN_STDDEV}"
    local delay_mean="${4:-$TURN_DELAY_MEAN}"
    local delay_stddev="${5:-$TURN_DELAY_STDDEV}"
    local concurrency="${6:-$CONCURRENCY}"

    local args=(
        --conversation-num "$conv_num"
        --conversation-turn-mean "$turn_mean"
        --conversation-turn-stddev "$turn_stddev"
        --concurrency "$concurrency"
    )

    [[ "$delay_mean" != "0" ]] && args+=(--conversation-turn-delay-mean "$delay_mean")
    [[ "$delay_stddev" != "0" ]] && args+=(--conversation-turn-delay-stddev "$delay_stddev")

    echo "${args[@]}"
}

build_token_args() {
    local input_mean="${1:-$INPUT_TOKENS_MEAN}"
    local output_mean="${2:-$OUTPUT_TOKENS_MEAN}"
    local input_stddev="${3:-$INPUT_TOKENS_STDDEV}"
    local output_stddev="${4:-$OUTPUT_TOKENS_STDDEV}"

    local args=(
        --synthetic-input-tokens-mean "$input_mean"
        --output-tokens-mean "$output_mean"
    )

    [[ -n "$input_stddev" ]] && args+=(--synthetic-input-tokens-stddev "$input_stddev")
    [[ -n "$output_stddev" ]] && args+=(--output-tokens-stddev "$output_stddev")

    echo "${args[@]}"
}

build_rate_args() {
    local args=()
    [[ -n "$REQUEST_RATE" ]] && args+=(--request-rate "$REQUEST_RATE")
    [[ -n "$REQUEST_RATE_MODE" ]] && args+=(--request-rate-mode "$REQUEST_RATE_MODE")
    echo "${args[@]}"
}

build_retry_args() {
    local args=()
    # When MAX_RETRIES is unset or 0, disable retries entirely (no retry flags).
    if [[ -n "$MAX_RETRIES" && "$MAX_RETRIES" != "0" ]]; then
        args+=(--max-retries "$MAX_RETRIES")
        [[ -n "$RETRY_DELAY" ]] && args+=(--retry-delay "$RETRY_DELAY")
        [[ -n "$RETRY_MAX_DELAY" ]] && args+=(--retry-max-delay "$RETRY_MAX_DELAY")
    fi
    echo "${args[@]}"
}

run_profile() {
    local conv_num="${1:-$CONVERSATION_NUM}"
    local turn_mean="${2:-$TURN_MEAN}"
    local turn_stddev="${3:-$TURN_STDDEV}"
    local delay_mean="${4:-$TURN_DELAY_MEAN}"
    local delay_stddev="${5:-$TURN_DELAY_STDDEV}"
    local concurrency="${6:-$CONCURRENCY}"
    local input_mean="${7:-$INPUT_TOKENS_MEAN}"
    local output_mean="${8:-$OUTPUT_TOKENS_MEAN}"
    local input_stddev="${9:-$INPUT_TOKENS_STDDEV}"
    local output_stddev="${10:-$OUTPUT_TOKENS_STDDEV}"

    local common conversation tokens rate retry
    common=$(build_common_args)
    conversation=$(build_conversation_args "$conv_num" "$turn_mean" "$turn_stddev" \
                                           "$delay_mean" "$delay_stddev" "$concurrency")
    tokens=$(build_token_args "$input_mean" "$output_mean" "$input_stddev" "$output_stddev")
    rate=$(build_rate_args)
    retry=$(build_retry_args)

    local total_requests=$((conv_num * turn_mean))
    echo "=== AIPerf Multi-Turn Conversation Benchmark ==="
    echo "Model:          $MODEL"
    echo "URL:            $URL"
    echo "Conversations:  $conv_num"
    echo "Turns:          mean=$turn_mean  stddev=$turn_stddev  (~$total_requests total requests)"
    echo "Turn delays:    mean=${delay_mean}ms  stddev=${delay_stddev}ms"
    echo "Input tokens:   mean=$input_mean  stddev=${input_stddev:-n/a}"
    echo "Output tokens:  mean=$output_mean  stddev=${output_stddev:-n/a}"
    echo "Concurrency:    $concurrency"
    [[ -n "$REQUEST_RATE" ]] && echo "Request rate:   $REQUEST_RATE (mode: ${REQUEST_RATE_MODE:-default})"
    [[ -n "$MAX_RETRIES" && "$MAX_RETRIES" != "0" ]] && echo "Retries:        max=$MAX_RETRIES  delay=${RETRY_DELAY:-n/a}s  max-delay=${RETRY_MAX_DELAY:-n/a}s"
    echo "================================================="

    # shellcheck disable=SC2086
    aiperf profile $common $conversation $tokens $rate $retry
}

###############################################################################
# Main
###############################################################################
case "${1:-}" in
    -h|--help|help)   usage ;;
esac

echo "--- Scenario: Fixed-Length Conversations ---"
run_profile "$CONVERSATION_NUM" "${TURN_MEAN:-3}" "0" \
            "0" "0" "$CONCURRENCY" \
            "$INPUT_TOKENS_MEAN" "$OUTPUT_TOKENS_MEAN" \
            "$INPUT_TOKENS_STDDEV" "$OUTPUT_TOKENS_STDDEV"
