#!/bin/bash

SVC="${1:-"kthena-router"}"

NS="${2:-"kthena-system"}"

bash /root/scripts/portforward/forward.sh $SVC 80 $NS
