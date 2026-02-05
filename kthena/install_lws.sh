#!/bin/bash

VERSION=v0.8.0
UNINSTALL=false

while getopts "u" opt; do
  case $opt in
    u)
      UNINSTALL=true
      ;;
    \?)
      echo "Usage: $0 [-u]" >&2
      exit 1
      ;;
  esac
done

if [ "$UNINSTALL" = true ]; then
    echo "Uninstalling LeaderWorkerSet $VERSION..."
    kubectl delete -f https://github.com/kubernetes-sigs/lws/releases/download/$VERSION/manifests.yaml
else
    echo "Installing LeaderWorkerSet $VERSION..."
    kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/$VERSION/manifests.yaml
fi
