#!/bin/bash

NODE_NAME=

CENTRAL_IP=
LOCAL_IP=

CLUSTER_IP_SUBNET=
MASTER_SWITCH_SUBNET=

ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" \
  external_ids:ovn-nb="tcp:$CENTRAL_IP:6641" \
  external_ids:ovn-encap-ip="$LOCAL_IP" \
  external_ids:ovn-encap-type="geneve"

ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="127.0.0.1:8080"

ovn-k8s-overlay master-init \
  --cluster-ip-subnet=$CLUSTER_IP_SUBNET \
  --master-switch-subnet="$MASTER_SWITCH_SUBNET" \
  --node-name="$NODE_NAME"


