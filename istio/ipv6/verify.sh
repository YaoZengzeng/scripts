#!/bin/bash

kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"

kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
