#!/bin/bash

NODE_NAME=

CENTRAL_IP=
LOCAL_IP=

K8S_API_SERVER_IP=

CLUSTER_IP_SUBNET=
MINION_SWITCH_SUBNET=

ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" \
  external_ids:ovn-nb="tcp:$CENTRAL_IP:6641" \
  external_ids:ovn-encap-ip="$LOCAL_IP" \
  external_ids:ovn-encap-type="geneve"

ovs-vsctl set Open_vSwitch . \
  external_ids:k8s-api-server="$K8S_API_SERVER_IP:8080"

ovn-k8s-overlay minion-init \
  --cluster-ip-subnet="$CLUSTER_IP_SUBNET" \
  --minion-switch-subnet="$MINION_SWITCH_SUBNET" \
  --node-name="$NODE_NAME"


