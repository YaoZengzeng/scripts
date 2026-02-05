#!/bin/bash

# Allow LOCAL_PORT to be configurable via argument 1
LOCAL_PORT="${1:-8080}"

# SERVICE_PORT is now argument 2, default to 80
SERVICE_PORT="${2:-80}"

# SVC is now argument 3, default to "kthena-router"
SVC="${3:-"kthena-router"}"

# NS is now argument 4, default to "kthena-system"
NS="${4:-"dev"}"

bash /root/scripts/portforward/forward.sh $SVC $LOCAL_PORT $SERVICE_PORT $NS
