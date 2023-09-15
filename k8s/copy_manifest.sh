#!/bin/bash

docker cp kube-apiserver.yaml $1:/etc/kubernetes/manifests/

docker cp kube-controller-manager.yaml $1:/etc/kubernetes/manifests/
