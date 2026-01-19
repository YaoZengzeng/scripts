#!/bin/bash

cd /root/kmesh

export ISTIO_VERSION="1.27.5"

./test/e2e/run_test.sh --skip-build -run "TestAddRemovePodWaypoint" --skip-cleanup-apps
