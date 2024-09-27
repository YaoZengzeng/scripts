#!/bin/bash

NAMESPACE="${1:-default}"

kmeshctl waypoint apply -n "$NAMESPACE" --enroll-namespace
