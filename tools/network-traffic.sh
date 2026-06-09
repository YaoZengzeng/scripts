#!/bin/bash

# Real-time network traffic monitor for Ubuntu 22.04
# Usage: ./network-traffic.sh [interface]
# If no interface specified, auto-detect the default route interface

INTERVAL=1

# Auto-detect interface or use argument
if [ -n "$1" ]; then
    IFACE="$1"
else
    IFACE=$(ip route | awk '/default/ {print $5; exit}')
fi

if [ -z "$IFACE" ]; then
    echo "Error: No network interface found."
    exit 1
fi

if [ ! -d "/sys/class/net/$IFACE" ]; then
    echo "Error: Interface '$IFACE' does not exist."
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

clear
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║         🌐 Real-Time Network Traffic Monitor                    ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo -e "${DIM}  Interface: ${BOLD}$IFACE${RESET}  ${DIM}| Refresh: ${INTERVAL}s | Press Ctrl+C to exit${RESET}"
echo ""
# Print 8 blank lines as placeholder for the first update
printf '\n\n\n\n\n\n\n\n'

# Get initial values
RX_PREV=$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes)
TX_PREV=$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes)
RX_TOTAL_START=$RX_PREV
TX_TOTAL_START=$TX_PREV

PEAK_RX=0
PEAK_TX=0

sleep $INTERVAL

while true; do
    RX_NOW=$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes)
    TX_NOW=$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes)

    RX_RATE=$(( (RX_NOW - RX_PREV) / INTERVAL ))
    TX_RATE=$(( (TX_NOW - TX_PREV) / INTERVAL ))

    [ "$RX_RATE" -gt "$PEAK_RX" ] && PEAK_RX=$RX_RATE
    [ "$TX_RATE" -gt "$PEAK_TX" ] && PEAK_TX=$TX_RATE

    RX_TOTAL=$(( RX_NOW - RX_TOTAL_START ))
    TX_TOTAL=$(( TX_NOW - TX_TOTAL_START ))

    # Determine max for bar graph scaling
    MAX_RATE=$PEAK_RX
    [ "$PEAK_TX" -gt "$MAX_RATE" ] && MAX_RATE=$PEAK_TX
    [ "$MAX_RATE" -eq 0 ] && MAX_RATE=1

    RX_BAR=$(bar_graph "$RX_RATE" "$MAX_RATE")
    TX_BAR=$(bar_graph "$TX_RATE" "$MAX_RATE")

    # Move cursor up to overwrite previous output (use \033[K to clear line remnants)
    printf '\033[8A'

    printf '\033[K  %b▼ RX (Download)%b\n' "${BOLD}${GREEN}" "${RESET}"
    printf '\033[K    Speed: %s  %b|%b  Peak: %s\n' "$(human_readable $RX_RATE)" "${DIM}" "${RESET}" "$(human_readable $PEAK_RX)"
    printf '\033[K    %b%s%b\n' "${GREEN}" "${RX_BAR}" "${RESET}"
    printf '\033[K\n'
    printf '\033[K  %b▲ TX (Upload)%b\n' "${BOLD}${RED}" "${RESET}"
    printf '\033[K    Speed: %s  %b|%b  Peak: %s\n' "$(human_readable $TX_RATE)" "${DIM}" "${RESET}" "$(human_readable $PEAK_TX)"
    printf '\033[K    %b%s%b\n' "${RED}" "${TX_BAR}" "${RESET}"
    printf '\033[K  %b── Total: RX %s / TX %s ──%b\n' "${DIM}" "$(human_readable_total $RX_TOTAL)" "$(human_readable_total $TX_TOTAL)" "${RESET}"

    RX_PREV=$RX_NOW
    TX_PREV=$TX_NOW

    sleep $INTERVAL
done
