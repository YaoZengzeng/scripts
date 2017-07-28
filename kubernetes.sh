#!/bin/bash

# Install docker
yum install -y docker

systemctl enable docker
systemctl start docker

# Install cni
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

setenforce 0

# Install kubelet kubeadm kubectl
yum install -y kubelet-1.7.0 kubeadm-1.7.0 kubectl-1.7.0

