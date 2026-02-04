#!/bin/bash

cd /root/kthena

make docker-build-router

make docker-build-controller

KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-agentcube-e2e}

kind load docker-image ghcr.io/volcano-sh/kthena-router:latest -n "${KIND_CLUSTER_NAME}"

kind load docker-image ghcr.io/volcano-sh/kthena-controller-manager:latest -n "${KIND_CLUSTER_NAME}"
