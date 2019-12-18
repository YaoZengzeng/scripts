#!/bin/sh
set -o errexit

yum install -y \
  btrfs-progs-devel \
  device-mapper-devel \
  glib2-devel \
  glibc-devel \
  glibc-static \
  gpgme-devel \
  libassuan-devel \
  libgpg-error-devel \
  libseccomp-devel \
  libselinux-devel \
  pkgconfig \
  runc

go get -d github.com/kubernetes-incubator/cri-o

cd $GOPATH/src/github.com/kubernetes-incubator/cri-o

make install.tools

make

sudo make install

# install cni
go get -d github.com/containernetworking/cni

cd $GOPATH/src/github.com/containernetworking/cni

./build

sudo mkdir -p /opt/cni/bin

sudo cp bin/* /opt/cni/bin/

sudo mkdir -p /etc/cni/net.d

sudo sh -c 'cat >/etc/cni/net.d/10-mynet.conf <<-EOF
{
    "cniVersion": "0.2.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.88.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0"  }
        ]
    }
}
EOF'

sudo sh -c 'cat >/etc/cni/net.d/99-loopback.conf <<-EOF
{
    "cniVersion": "0.2.0",
    "type": "loopback"
}
EOF'

