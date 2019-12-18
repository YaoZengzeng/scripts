#!/bin/bash

curl -L https://storage.googleapis.com/golang/go1.13.1.linux-amd64.tar.gz | tar -C /usr/local -zxf -
echo 'export GOPATH=/gopath/' >> /root/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin:/usr/local/bin:/usr/local/go/bin/' >> /root/.bashrc
source /root/.bashrc
go get github.com/tools/godep

