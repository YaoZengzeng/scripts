#!/bin/bash

while true; do

    bash /root/scripts/k8s/delete_ns.sh "echo"
    
    cd /root/kmesh

    #./test/e2e/run_test.sh --skip-install-dep --skip-build --ipv6 -run 'TestKmeshRestart' --skip-cleanup-apps -count 1
    #./test/e2e/run_test.sh --only-run-tests -run 'TestKmeshRestart' --skip-cleanup-apps -count 1
    #./test/e2e/run_test.sh --only-run-tests -run 'TestKmeshRestart' --skip-cleanup-apps --istio.test.ci -count 100 -failfast
    ./test/e2e/run_test.sh --skip-install-dep --skip-build --ipv6  --skip-cleanup-apps -count 1
    
    # check the exit status of a command
    if [ $? -ne 0 ]; then
        echo "Command failed. Exiting..."
        break
    fi

done
