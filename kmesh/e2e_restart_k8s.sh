#!/bin/bash

cd /root/kmesh

./test/e2e/run_test.sh --skip-install-dep --skip-build --skip-cleanup-apps
