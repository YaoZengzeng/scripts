#!/bin/bash

ISTIOSYSTEM="istio-system"

alias ki="kubectl -n ${ISTIOSYSTEM}"
alias kigp="kubectl get pods -n ${ISTIOSYSTEM}"
alias kidp="kubectl -n ${ISTIOSYSTEM} delete pods"
alias kilp="kubectl -n ${ISTIOSYSTEM} logs"
alias kidsp="kubectl -n ${ISTIOSYSTEM} describe pods"
alias kigs="kubectl get services -n ${ISTIOSYSTEM}"

SYSTEM="kube-system"

alias k="kubectl -n ${SYSTEM}"
alias kkgp="kubectl get pods -n ${SYSTEM}"
alias kkdp="kubectl -n ${SYSTEM} delete pods"
alias kklp="kubectl -n ${SYSTEM} logs"
alias kkdsp="kubectl -n ${SYSTEM} describe pods"
alias kkgs="kubectl get services -n ${SYSTEM}"

alias k="kubectl"
alias kgp="kubectl get pods"
alias klp="kubectl logs"
alias kdp="kubectl delete pods"
alias kep="kubectl exec -it"
alias kdsp="kubectl describe pods"
alias kgs="kubectl get services"

alias di="docker images"
alias dp="docker ps"
alias dr="docker run"
alias dc="docker cp"

alias configdump="curl http://127.0.0.1:15000/config_dump"
