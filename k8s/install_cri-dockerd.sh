#!/bin/bash

#VERSION=0.3.3
#ARCH=amd64

#wget https://github.com/Mirantis/cri-dockerd/releases/download/v${VERSION}/cri-dockerd-${VERSION}.${ARCH}.tgz

#tar -xzf cri-dockerd-${VERSION}.${ARCH}.tgz

git clone https://github.com/Mirantis/cri-dockerd.git

cd cri-dockerd

make cri-dockerd

install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd

install packaging/systemd/* /etc/systemd/system

sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

systemctl daemon-reload

systemctl enable cri-docker.service

systemctl enable --now cri-docker.socket
