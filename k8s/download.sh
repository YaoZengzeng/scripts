#!/bin/bash

sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg

echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 下载指定版本的k8s组件
# apt-cache madison kubectl | grep 1.21 // 查看支持哪些k8s版本

sudo apt-get update

apt install -y kubelet=1.28.1-00 kubeadm=1.28.1-00 kubectl=1.28.1-00

