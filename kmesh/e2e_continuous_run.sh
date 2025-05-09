#!/bin/bash

cd /root/kmesh

#./test/e2e/run_test.sh --only-run-tests -run "TestServiceEntrySelectsWorkloadEntry" --skip-cleanup-apps
./test/e2e/run_test.sh --only-run-tests -count 1000 -timeout 1000000s
