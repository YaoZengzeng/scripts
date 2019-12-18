#!/bin/sh

installed () {
	command -v "$1" > /dev/null 2>&1
}

if ! installed etcd; then
	ETCD_VER=v3.1.3
	DOWNLOAD_URL=https://github.com/coreos/etcd/releases/download
	curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	mkdir -p /tmp/test-etcd && tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1

	etcd --version

	ETH0=`ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}' | tr -d "addr:"`

	ENDPOINTS=$ETH0:2379
cat >> $HOME/.bashrc <<EOF
alias etcdctl="etcdctl --endpoints=$ENDPOINTS"
EOF
fi

TOKEN=token-01
CLUSTER_STATE=new
if [ "$1" == "1" ]; then
	NAME_1=$2
	HOST_1=$3
	CLUSTER=${NAME_1}=http://${HOST_1}:2380
else
	NAME_1=$1
	NAME_2=$2
	HOST_1=$3
	HOST_2=$4
	CLUSTER=${NAME_1}=http://${HOST_1}:2380,${NAME_2}=http://${HOST_2}:2380
fi

THIS_NAME=${NAME_1}
THIS_IP=${HOST_1}
etcd --data-dir=data.etcd --name ${THIS_NAME} \
    --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
    --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://${THIS_IP}:2379 \
    --initial-cluster ${CLUSTER} \
    --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}

