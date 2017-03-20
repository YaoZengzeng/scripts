#!/bin/sh

COREOS=$GOPATH/src/github.com/coreos

if [ ! -d $COREOS ]; then
	mkdir -p $COREOS
fi

if [ -d $COREOS/flannel ]; then
	echo "flannel git repo already exist"
else
	git clone https://github.com/coreos/flannel.git $COREOS/flannel
fi

installed () {
	command -v "$1" > /dev/null 2>&1
}

if ! installed flanneld; then
	cd $COREOS/flannel

	make dist/flanneld-amd64
	cp dist/flanneld-amd64 /usr/local/bin/flanneld
fi

ETH0=`ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}' | tr -d "addr:"`

FLANNELD_ETCD_ENDPOINTS=http://$ETH0:2379

((flanneld --etcd-endpoints=${FLANNELD_ETCD_ENDPOINTS} )&)

