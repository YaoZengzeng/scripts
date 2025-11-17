#!/bin/bash

# run the example

export API_TOKEN=$(kubectl create token my-app -n test --duration=24h)

cd /root/agentcube/example

go run client.go
