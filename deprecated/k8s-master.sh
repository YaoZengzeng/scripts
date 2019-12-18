#!/bin/bash

# On the master node, start etcd
docker run \
  --net=host \
  --detach \
  gcr.io/google_containers/etcd:2.0.12 \
  /usr/local/bin/etcd \
    --addr=127.0.0.1:4001 \
    --bind-addr=0.0.0.0:4001 \
    --data-dir=/var/etcd/data

# install kube-apiserver
nohup kube-apiserver \
  --service-cluster-ip-range=192.168.200.0/24 \
  --address=0.0.0.0 \
  --etcd-servers=http://127.0.0.1:4001 \
  --v=2 \
  2>&1 > /dev/null &


# install kube-controller-manager
nohup kube-controller-manager \
  --master=127.0.0.1:8080 \
  --v=2 \
  2>&1 > /dev/null &

# install kube-scheduler
nohup kube-scheduler \
  --master=127.0.0.1:8080 \
  --v=2 \
  2>&1 > /dev/null &


