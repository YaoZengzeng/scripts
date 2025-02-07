#!/bin/bash

NAMESPACE="${3:-default}"

NAME="$2"

COMPONENT="$1"

egctl config envoy-proxy $COMPONENT $NAME -n $NAMESPACE
