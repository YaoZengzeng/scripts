#!/bin/bash

kubeadm reset --cri-socket="unix:///var/run/cri-dockerd.sock"
