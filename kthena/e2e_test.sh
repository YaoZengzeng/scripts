#!/bin/bash

cd /root/kthena

#go test ./test/e2e/controller-manager/ -v -run "^TestModelServingRollingUpdateMaxUnavailable$" -count 100

go test ./test/e2e/controller-manager/ -v -run "TestModelServing" -count 100
