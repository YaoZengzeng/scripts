#!/bin/bash

cd /root/kmesh

#./test/e2e/run_test.sh --skip-install-dep --skip-build -run "TestBookinfo\|TestKmeshRestart" --skip-cleanup-apps
./test/e2e/run_test.sh --skip-install-dep --skip-build --skip-cleanup-apps
