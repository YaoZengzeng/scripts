#!/bin/bash

cd /root/kthena

make docker-build-router

kind load docker-image ghcr.io/volcano-sh/kthena-router:latest -n agent-sandbox
