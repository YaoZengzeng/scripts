#!/bin/bash

# Install docker
apt-get update
apt-get install -y docker.io

mkdir k8s
cd k8s

wget https://github.com/kubernetes/kubernetes/releases/download/v1.5.3/kubernetes.tar.gz

tar xvzf kubernetes.tar.gz

./kubernetes/cluster/get-kube-binaries.sh

mkdir server

cd server

tar xvzf ../kubernetes/server/kubernetes-server-linux-amd64.tar.gz

cd kubernetes/server/bin

cp kube-apiserver kube-controller-manager kube-scheduler kubelet kubectl /usr/bin

# Install cni
mkdir -p /opt/cni/bin && cd /opt/cni/bin

wget https://github.com/containernetworking/cni/releases/download/v0.5.2/cni-amd64-v0.5.2.tgz

tar xvzf cni-amd64-v0.5.2.tgz

