#!/bin/bash

ISTIOSYSTEM="istio-system"

alias ki="kubectl -n ${ISTIOSYSTEM}"
alias kigp="kubectl get pods -n ${ISTIOSYSTEM}"
alias kidp="kubectl -n ${ISTIOSYSTEM} delete pods"
alias kilp="kubectl -n ${ISTIOSYSTEM} logs"
alias kidsp="kubectl -n ${ISTIOSYSTEM} describe pods"
alias kigs="kubectl get services -n ${ISTIOSYSTEM}"

KMESHSYSTEM="kmesh-system"

alias kk="kubectl -n ${KMESHSYSTEM}"
alias kkgp="kubectl get pods -n ${KMESHSYSTEM}"
alias kkdp="kubectl -n ${KMESHSYSTEM} delete pods"
alias kklp="kubectl -n ${KMESHSYSTEM} logs"
alias kkdsp="kubectl -n ${KMESHSYSTEM} describe pods"
alias kkgs="kubectl get services -n ${KMESHSYSTEM}"

TESTNS="test"

alias kt="kubectl -n ${TESTNS}"
alias ktgp="kubectl get pods -n ${TESTNS}"
alias ktdp="kubectl -n ${TESTNS} delete pods"
alias ktlp="kubectl -n ${TESTNS} logs"
alias ktdsp="kubectl -n ${TESTNS} describe pods"
alias ktgs="kubectl get services -n ${TESTNS}"

OLLAMANS="ollama"

alias ko="kubectl -n ${OLLAMANS}"
alias kogp="kubectl get pods -n ${OLLAMANS}"
alias kodp="kubectl -n ${OLLAMANS} delete pods"
alias kolp="kubectl -n ${OLLAMANS} logs"
alias kodsp="kubectl -n ${OLLAMANS} describe pods"
alias kogs="kubectl get services -n ${OLLAMANS}"

alias k="kubectl"
alias kgp="kubectl get pods"
alias kgpa="kubectl get pods --all-namespaces"
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
