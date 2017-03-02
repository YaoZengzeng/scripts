#!/bin/bash

RUNTIME=docker

if grep -qi "CentOS" /etc/*-release; then
	PM='yum'
elif grep -Eqi "Ubuntu" /etc/*-release; then
	PM='apt-get'
fi

K8SPATH="$GOPATH/src/k8s.io/kubernetes"

if [ -d $K8SPATH ]; then
	echo "K8s git repo already exist"
else
	git clone https://github.com/kubernetes/kubernetes.git $K8SPATH
fi

cd $K8SPATH

# install etcd if needed
which etcd > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "ectd already exist"
else
	ETCD_VER=v3.1.2
	DOWNLOAD_URL=https://github.com/coreos/etcd/releases/download
	curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	mkdir -p /tmp/test-etcd && tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
fi

#install ginkgo if needed
which ginkgo > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "ginkgo already exist"
else
	go get github.com/onsi/ginkgo/ginkgo
	go get github.com/onsi/gomega
fi

#install gcc if needed
which gcc > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "gcc already exist"
else
	$PM install -y gcc
fi

#make log dir
if [ -d $HOME/log ]; then
	echo "log dir already exist"
else
	mkdir $HOME/log
fi

#node e2e test
cd $K8SPATH
if [ $RUNTIME = "docker" ]; then
	(( make test-e2e-node PARALLELISM=1 2>&1 | tee $HOME/log/node-e2e.log )&)
elif [ $RUNTIME = "frakti" ]; then
	(( make test-e2e-node PARALLELISM=1 RUNTIME=remote TEST_ARGS='--kubelet-flags="--container-runtime-endpoint=/var/run/frakti.sock --feature-gates=AllAlpha=true,Accelerators=false"' 2>&1 | tee $HOME/log/node-e2e.log )&)
fi

