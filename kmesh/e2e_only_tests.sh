#!/bin/bash

cd /root/kmesh

./test/e2e/run_test.sh --only-run-tests -run "TestKmeshRestart" --skip-cleanup-apps
