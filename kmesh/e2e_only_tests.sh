#!/bin/bash

cd /root/kmesh

./test/e2e/run_test.sh --only-run-tests --skip-cleanup-apps
