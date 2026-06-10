#!/bin/bash

# Real-time network traffic monitor for Ubuntu 22.04
# Usage: ./network-traffic.sh [interface|all]
# If no interface specified, monitor all active interfaces simultaneously
# Specify a single interface name to monitor only that one

INTERVAL=1

# Detect interfaces
if [ -n "$1" ] && [ "$1" != "all" ]; then
    # Single interface mode
    if [ ! -d "/sys/class/net/$1" ]; then
        echo "Error: Interface '$1' does not exist."
        exit 1
    fi
    IFACES=("$1")
else
    # All active interfaces (exclude lo by default)
    mapfile -t IFACES < <(ls /sys/class/net/ | grep -v '^lo$' | sort)
fi

if [ ${#IFACES[@]} -eq 0 ]; then
    echo "Error: No network interface found."
    exit 1
fi

human_readable() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        printf "%8.2f GB/s" "$(echo "scale=2; $bytes/1073741824" | bc)"
    elif [ "$bytes" -ge 1048576 ]; then
        printf "%8.2f MB/s" "$(echo "scale=2; $bytes/1048576" | bc)"
    elif [ "$bytes" -ge 1024 ]; then
        printf "%8.2f KB/s" "$(echo "scale=2; $bytes/1024" | bc)"
    else
        printf "%8.2f  B/s" "$(echo "scale=2; $bytes/1" | bc)"
    fi
}

human_readable_total() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        printf "%.2f GB" "$(echo "scale=2; $bytes/1073741824" | bc)"
    elif [ "$bytes" -ge 1048576 ]; then
        printf "%.2f MB" "$(echo "scale=2; $bytes/1048576" | bc)"
    elif [ "$bytes" -ge 1024 ]; then
        printf "%.2f KB" "$(echo "scale=2; $bytes/1024" | bc)"
    else
        printf "%d B" "$bytes"
    fi
}

bar_graph() {
    local value=$1
    local max=$2
    local width=30
    local filled=0

    if [ "$max" -gt 0 ]; then
        filled=$(( value * width / max ))
    fi
    [ "$filled" -gt "$width" ] && filled=$width

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<width; i++)); do bar+="░"; done
    echo "$bar"
}

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Hide cursor and restore on exit
tput civis 2>/dev/null
trap 'tput cnorm 2>/dev/null; echo; exit 0' INT TERM

# Build interface list display
IFACE_LIST=$(printf '%s ' "${IFACES[@]}")

clear
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║         🌐 Real-Time Network Traffic Monitor                    ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo -e "${DIM}  Interfaces: ${BOLD}${IFACE_LIST}${RESET}  ${DIM}| Refresh: ${INTERVAL}s | Press Ctrl+C to exit${RESET}"
echo ""

# Calculate display lines: 4 lines per interface + 1 summary line
NUM_IFACES=${#IFACES[@]}
DISPLAY_LINES=$(( NUM_IFACES * 4 + 1 ))

# Print blank lines as placeholder
for ((i=0; i<DISPLAY_LINES; i++)); do printf '\n'; done

# Initialize per-interface tracking using associative arrays
declare -A RX_PREV TX_PREV RX_TOTAL_START TX_TOTAL_START PEAK_RX PEAK_TX

for iface in "${IFACES[@]}"; do
    RX_PREV[$iface]=$(cat /sys/class/net/"$iface"/statistics/rx_bytes)
    TX_PREV[$iface]=$(cat /sys/class/net/"$iface"/statistics/tx_bytes)
    RX_TOTAL_START[$iface]=${RX_PREV[$iface]}
    TX_TOTAL_START[$iface]=${TX_PREV[$iface]}
    PEAK_RX[$iface]=0
    PEAK_TX[$iface]=0
done

sleep $INTERVAL

while true; do
    # Move cursor up to overwrite previous output
    printf "\033[${DISPLAY_LINES}A"

    TOTAL_RX_SESSION=0
    TOTAL_TX_SESSION=0

    for iface in "${IFACES[@]}"; do
        RX_NOW=$(cat /sys/class/net/"$iface"/statistics/rx_bytes)
        TX_NOW=$(cat /sys/class/net/"$iface"/statistics/tx_bytes)

        RX_RATE=$(( (RX_NOW - ${RX_PREV[$iface]}) / INTERVAL ))
        TX_RATE=$(( (TX_NOW - ${TX_PREV[$iface]}) / INTERVAL ))

        [ "$RX_RATE" -gt "${PEAK_RX[$iface]}" ] && PEAK_RX[$iface]=$RX_RATE
        [ "$TX_RATE" -gt "${PEAK_TX[$iface]}" ] && PEAK_TX[$iface]=$TX_RATE

        RX_TOTAL=$(( RX_NOW - ${RX_TOTAL_START[$iface]} ))
        TX_TOTAL=$(( TX_NOW - ${TX_TOTAL_START[$iface]} ))
        TOTAL_RX_SESSION=$(( TOTAL_RX_SESSION + RX_TOTAL ))
        TOTAL_TX_SESSION=$(( TOTAL_TX_SESSION + TX_TOTAL ))

        # Determine max for bar graph scaling (per interface)
        MAX_RATE=${PEAK_RX[$iface]}
        [ "${PEAK_TX[$iface]}" -gt "$MAX_RATE" ] && MAX_RATE=${PEAK_TX[$iface]}
        [ "$MAX_RATE" -eq 0 ] && MAX_RATE=1

        RX_BAR=$(bar_graph "$RX_RATE" "$MAX_RATE")
        TX_BAR=$(bar_graph "$TX_RATE" "$MAX_RATE")

        printf '\033[K  %b[%s]%b  %b▼%b %s  %b▲%b %s  %b|%b  Total: RX %s / TX %s\n' \
            "${BOLD}${CYAN}" "$iface" "${RESET}" \
            "${GREEN}" "${RESET}" "$(human_readable $RX_RATE)" \
            "${RED}" "${RESET}" "$(human_readable $TX_RATE)" \
            "${DIM}" "${RESET}" \
            "$(human_readable_total $RX_TOTAL)" "$(human_readable_total $TX_TOTAL)"
        printf '\033[K    %b▼ RX%b %b%s%b  Peak: %s\n' "${GREEN}" "${RESET}" "${GREEN}" "${RX_BAR}" "${RESET}" "$(human_readable ${PEAK_RX[$iface]})"
        printf '\033[K    %b▲ TX%b %b%s%b  Peak: %s\n' "${RED}" "${RESET}" "${RED}" "${TX_BAR}" "${RESET}" "$(human_readable ${PEAK_TX[$iface]})"
        printf '\033[K\n'

        RX_PREV[$iface]=$RX_NOW
        TX_PREV[$iface]=$TX_NOW
    done

    printf '\033[K  %b── Grand Total: RX %s / TX %s ──%b\n' "${DIM}" \
        "$(human_readable_total $TOTAL_RX_SESSION)" "$(human_readable_total $TOTAL_TX_SESSION)" "${RESET}"

    sleep $INTERVAL
done
