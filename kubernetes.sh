#!/bin/bash

# Install hyper
curl -sSL https://hypercontainer.io/install | bash

echo -e "Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config

systemctl enable hyperd
systemctl restart hyperd

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
yum install -y kubernetes-cni

# Install kubelet kubeadm kubectl
yum install -y kubelet kubeadm kubectl
