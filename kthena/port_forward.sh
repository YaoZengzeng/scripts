#!/bin/bash

# Allow SERVICE_PORT to be configurable via argument 1, default to 80
SERVICE_PORT="${1:-80}"

SVC="${2:-"kthena-router"}"

NS="${3:-"kthena-system"}"


bash /root/scripts/portforward/forward.sh $SVC 80 $SERVICE_PORT $NS
