#!/bin/bash

SVC="${1:-"kthena-router"}"

NS="${2:-"kthena-system"}"

# Allow SERVICE_PORT to be configurable via argument 3, default to 80
SERVICE_PORT="${3:-80}"

bash /root/scripts/portforward/forward.sh $SVC 80 $SERVICE_PORT $NS
