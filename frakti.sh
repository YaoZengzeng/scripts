#!/bin/bash

if [ ! -d $GOPATH/src/k8s.io/frakti ]; then
	git clone https://github.com/kubernetes/frakti.git $GOPATH/src/k8s.io/frakti
	cd $GOPATH/src/k8s.io/frakti
	make && make install
fi

((frakti --v=3 --logtostderr --listen=/var/run/frakti.sock --hyper-endpoint=127.0.0.1:22318 2>&1 | tee $HOME/log/frakti.log)&)

