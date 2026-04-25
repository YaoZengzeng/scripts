#!/usr/bin/env bash
# Prefix Synthesis Benchmark Script for AIPerf (Client-Side Mode)
# Reference: https://github.com/ai-dynamo/aiperf/blob/main/docs/tutorials/prefix-synthesis.md
set -euo pipefail

###############################################################################
# Configuration
###############################################################################
MODEL="${MODEL:-Qwen/Qwen3-0.6B}"
TOKENIZER="${TOKENIZER:-}"            # defaults to MODEL if empty
URL="${URL:-172.236.135.114:80}"
ENDPOINT_TYPE="${ENDPOINT_TYPE:-chat}"
INPUT_FILE="${INPUT_FILE:-traces/production.jsonl}"
BLOCK_SIZE="${BLOCK_SIZE:-512}"
CONCURRENCY="${CONCURRENCY:-}"        # empty = aiperf default (1)
REQUEST_COUNT="${REQUEST_COUNT:-}"     # empty = determined by dataset
REQUEST_RATE="${REQUEST_RATE:-}"       # empty = not set
STREAMING="${STREAMING:-true}"
UI="${UI:-dashboard}"

# Synthesis parameters
SPEEDUP_RATIO="${SPEEDUP_RATIO:-1.0}"
PREFIX_LEN_MULTIPLIER="${PREFIX_LEN_MULTIPLIER:-1.0}"
PREFIX_ROOT_MULTIPLIER="${PREFIX_ROOT_MULTIPLIER:-1}"
PROMPT_LEN_MULTIPLIER="${PROMPT_LEN_MULTIPLIER:-1.0}"
MAX_ISL="${MAX_ISL:-}"                # empty = no filter
MAX_OSL="${MAX_OSL:-}"                # empty = no cap

# Output
ARTIFACT_DIR="${ARTIFACT_DIR:-artifacts}"
ANALYSIS_OUTPUT="${ANALYSIS_OUTPUT:-analysis.json}"

###############################################################################
# Helpers
###############################################################################
usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
  analyze          Analyze trace file for ISL/OSL distributions and cache hit rates
  benchmark        Run prefix synthesis benchmark (default parameters)
  high-cache       Scenario: simulate high cache hit rate
  load-test        Scenario: load testing with scaled timeline (10x speedup)
  stress-context   Scenario: stress test with extended context lengths
  multi-turn       Scenario: controlled multi-turn with diverse prefix patterns
  sweep            Run a sweep over multiple prefix-root-multiplier values

Environment variables (override defaults):
  MODEL              Model name                            (default: Qwen/Qwen3-0.6B)
  TOKENIZER          Tokenizer (defaults to MODEL)
  URL                Server URL                            (default: localhost:8000)
  ENDPOINT_TYPE      Endpoint type                         (default: chat)
  INPUT_FILE         Path to mooncake trace JSONL file     (default: traces/production.jsonl)
  BLOCK_SIZE         KV cache block size for analysis      (default: 512)
  CONCURRENCY        Concurrent requests                   (default: aiperf default)
  REQUEST_COUNT      Total request count                   (default: auto)
  REQUEST_RATE       Requests per second                   (default: not set)
  STREAMING          Enable streaming                      (default: true)
  UI                 UI type: dashboard|simple|none        (default: simple)

  SPEEDUP_RATIO              Timestamp scaling             (default: 1.0)
  PREFIX_LEN_MULTIPLIER      Core prefix length scaling    (default: 1.0)
  PREFIX_ROOT_MULTIPLIER     Number of independent trees   (default: 1)
  PROMPT_LEN_MULTIPLIER      Unique prompt length scaling  (default: 1.0)
  MAX_ISL                    Max input sequence length      (default: none)
  MAX_OSL                    Max output sequence length     (default: none)

  ARTIFACT_DIR       Output directory                      (default: artifacts)
  ANALYSIS_OUTPUT    Analysis JSON output path             (default: analysis.json)

Examples:
  INPUT_FILE=prod.jsonl $0 analyze
  INPUT_FILE=prod.jsonl MODEL=meta-llama/Llama-3-8B URL=gpu-server:8000 $0 benchmark
  SPEEDUP_RATIO=5.0 INPUT_FILE=prod.jsonl $0 load-test
  PREFIX_ROOT_MULTIPLIER=1,3,5,10 INPUT_FILE=prod.jsonl $0 sweep
EOF
    exit 1
}

build_common_args() {
    local args=(
        --model "$MODEL"
        --endpoint-type "$ENDPOINT_TYPE"
        --url "$URL"
        --input-file "$INPUT_FILE"
        --custom-dataset-type mooncake_trace
        --ui-type "$UI"
        --output-artifact-dir "$ARTIFACT_DIR"
    )

    [[ -n "$TOKENIZER" ]] && args+=(--tokenizer "$TOKENIZER")
    [[ "$STREAMING" == "true" ]] && args+=(--streaming)
    [[ -n "$CONCURRENCY" ]] && args+=(--concurrency "$CONCURRENCY")
    [[ -n "$REQUEST_COUNT" ]] && args+=(--request-count "$REQUEST_COUNT")
    [[ -n "$REQUEST_RATE" ]] && args+=(--request-rate "$REQUEST_RATE")

    echo "${args[@]}"
}

build_synthesis_args() {
    local speedup="${1:-$SPEEDUP_RATIO}"
    local prefix_len="${2:-$PREFIX_LEN_MULTIPLIER}"
    local prefix_root="${3:-$PREFIX_ROOT_MULTIPLIER}"
    local prompt_len="${4:-$PROMPT_LEN_MULTIPLIER}"

    local args=(
        --synthesis-speedup-ratio "$speedup"
        --synthesis-prefix-len-multiplier "$prefix_len"
        --synthesis-prefix-root-multiplier "$prefix_root"
        --synthesis-prompt-len-multiplier "$prompt_len"
    )

    [[ -n "$MAX_ISL" ]] && args+=(--synthesis-max-isl "$MAX_ISL")
    [[ -n "$MAX_OSL" ]] && args+=(--synthesis-max-osl "$MAX_OSL")

    echo "${args[@]}"
}

run_profile() {
    local common synthesis
    common=$(build_common_args)
    synthesis=$(build_synthesis_args "$@")

    echo "=== AIPerf Prefix Synthesis Benchmark (Client-Side Mode) ==="
    echo "Model:       $MODEL"
    echo "URL:         $URL"
    echo "Input file:  $INPUT_FILE"
    echo "Synthesis:   speedup=${1:-$SPEEDUP_RATIO}  prefix_len=${2:-$PREFIX_LEN_MULTIPLIER}" \
         " root=${3:-$PREFIX_ROOT_MULTIPLIER}  prompt_len=${4:-$PROMPT_LEN_MULTIPLIER}"
    [[ -n "$MAX_ISL" ]] && echo "Max ISL:     $MAX_ISL"
    [[ -n "$MAX_OSL" ]] && echo "Max OSL:     $MAX_OSL"
    echo "============================================================"

    # shellcheck disable=SC2086
    aiperf profile $common $synthesis
}

###############################################################################
# Commands
###############################################################################
cmd_analyze() {
    echo "=== Analyzing trace: $INPUT_FILE (block-size=$BLOCK_SIZE) ==="
    local args=(
        --input-file "$INPUT_FILE"
        --block-size "$BLOCK_SIZE"
    )
    [[ -n "$ANALYSIS_OUTPUT" ]] && args+=(--output-file "$ANALYSIS_OUTPUT")

    aiperf analyze-trace "${args[@]}"
    echo "=== Analysis complete. Output: $ANALYSIS_OUTPUT ==="
}

cmd_benchmark() {
    run_profile "$SPEEDUP_RATIO" "$PREFIX_LEN_MULTIPLIER" \
                "$PREFIX_ROOT_MULTIPLIER" "$PROMPT_LEN_MULTIPLIER"
}

cmd_high_cache() {
    echo "--- Scenario: High Cache Hit Rate ---"
    run_profile "${SPEEDUP_RATIO}" "${PREFIX_LEN_MULTIPLIER}" \
                "${PREFIX_ROOT_MULTIPLIER:-5}" "${PROMPT_LEN_MULTIPLIER:-0.8}"
}

cmd_load_test() {
    echo "--- Scenario: Load Testing (10x speedup) ---"
    run_profile "${SPEEDUP_RATIO:-10.0}" "${PREFIX_LEN_MULTIPLIER}" \
                "${PREFIX_ROOT_MULTIPLIER}" "${PROMPT_LEN_MULTIPLIER}"
}

cmd_stress_context() {
    echo "--- Scenario: Stress Testing with Extended Context ---"
    MAX_ISL="${MAX_ISL:-8192}" \
    run_profile "${SPEEDUP_RATIO}" "${PREFIX_LEN_MULTIPLIER:-2.0}" \
                "${PREFIX_ROOT_MULTIPLIER}" "${PROMPT_LEN_MULTIPLIER}"
}

cmd_multi_turn() {
    echo "--- Scenario: Controlled Multi-Turn Simulation ---"
    run_profile "${SPEEDUP_RATIO}" "${PREFIX_LEN_MULTIPLIER}" \
                "${PREFIX_ROOT_MULTIPLIER:-10}" "${PROMPT_LEN_MULTIPLIER:-1.2}"
}

cmd_sweep() {
    local roots="${PREFIX_ROOT_MULTIPLIER:-1,3,5,10}"
    IFS=',' read -ra ROOT_VALUES <<< "$roots"

    echo "=== Sweeping prefix-root-multiplier: ${ROOT_VALUES[*]} ==="
    for root in "${ROOT_VALUES[@]}"; do
        echo ""
        echo ">>> prefix-root-multiplier = $root"
        run_profile "$SPEEDUP_RATIO" "$PREFIX_LEN_MULTIPLIER" \
                    "$root" "$PROMPT_LEN_MULTIPLIER"
    done
    echo "=== Sweep complete ==="
}

###############################################################################
# Main
###############################################################################
[[ $# -lt 1 ]] && usage

case "$1" in
    analyze)        cmd_analyze ;;
    benchmark)      cmd_benchmark ;;
    high-cache)     cmd_high_cache ;;
    load-test)      cmd_load_test ;;
    stress-context) cmd_stress_context ;;
    multi-turn)     cmd_multi_turn ;;
    sweep)          cmd_sweep ;;
    -h|--help|help) usage ;;
    *)              echo "Unknown command: $1"; usage ;;
esac