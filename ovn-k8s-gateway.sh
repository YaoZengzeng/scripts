#!/bin/bash

NODE_NAME=m1

CLUSTER_IP_SUBNET=192.168.0.0/16

PHYSICAL_IP=

EXTERNAL_GATEWAY=

K8S_API_SERVER_IP=

NIC=eth0

OVSBR=breth0

ovs-vsctl set Open_vSwitch . \
  external_ids:k8s-api-server="$K8S_API_SERVER_IP:8080"

ovn-k8s-util nics-to-bridge $NIC

ovn-k8s-overlay gateway-init \
	--cluster-ip-subnet="$CLUSTER_IP_SUBNET" \
	--bridge-interface $OVSBR \
	--physical-ip "$PHYSICAL_IP" \
	--node-name="$NODE_NAME" \
	--default-gw "$EXTERNAL_GATEWAY"

ovn-k8s-gateway-helper --physical-bridge=$OVSBR --physical-interface=$NIC \
	--pidfile --detach

