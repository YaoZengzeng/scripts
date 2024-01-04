#!/bin/bash

# install latest version
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# install specific version
curl -LO https://dl.k8s.io/release/v1.26.3/bin/linux/amd64/kubectl

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm ./kubectl

kubectl version --client
