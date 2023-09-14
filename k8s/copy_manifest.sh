#!/bin/bash

CID=685b4b50a00f

docker cp kube-apiserver.yaml $CID:/etc/kubernetes/manifests/

docker cp kube-controller-manager.yaml $CID:/etc/kubernetes/manifests/
