#!/bin/bash

# curl -LO https://raw.githubusercontent.com/cilium/cilium/1.13.2/Documentation/installation/kind-config.yaml

kind create cluster --config=kind-config.yaml

rm kind-config.yaml
