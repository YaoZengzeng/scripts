#!/bin/bash

VERSION=1.21.1

wget https://go.dev/dl/go$VERSION.linux-amd64.tar.gz

rm -rf /usr/local/go && tar -C /usr/local -xzf go$VERSION.linux-amd64.tar.gz

rm go$VERSION.linux-amd64.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin:/root/go/bin" >> /root/.bashrc

