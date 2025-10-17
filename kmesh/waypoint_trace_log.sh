#!/bin/bash

WAYPOINT_NAME="${1:-"waypoint"}"
NAMESPACE="${2:-"default"}"

istioctl pc log $WAYPOINT_NAME.$NAMESPACE --level trace
