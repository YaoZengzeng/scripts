#!/bin/bash

bash /root/scripts/k8s/kind/create_kind_cluster.sh

bash /root/scripts/istio/install/install_ambient.sh

bash ./install.sh

