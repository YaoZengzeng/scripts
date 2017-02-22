#!/bin/bash

# Remove unofficial Docker packages
yum -y remove docker docker-common container-selinux docker-selinux docker-engine

# Set up the repository
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Update the yum package index
yum makecache fast

# install the latest version of Docker
yum -y install docker-ce

systemctl start docker

# Test
docker run hello-world

