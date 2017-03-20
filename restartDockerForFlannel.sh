#!/bin/sh

systemctl stop docker.service

source /run/flannel/subnet.env
((docker daemon --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU})&)

