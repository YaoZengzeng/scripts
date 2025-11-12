#!/bin/bash

cd /root/agentcube

make docker-build

make sandbox-build

kind load docker-image agentcube-apiserver:latest -n agent-sandbox

kind load docker-image sandbox:latest -n agent-sandbox
