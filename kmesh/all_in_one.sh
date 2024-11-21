#!/bin/bash

CLUSTER_NAME="${1:-kmesh}"

bash /root/scripts/k8s/kind/create_kind_cluster.sh $CLUSTER_NAME

bash /root/scripts/istio/install/install_ambient.sh

export local_image=false 

bash ./install.sh

