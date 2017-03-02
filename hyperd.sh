#!/bin/bash

HYPERHQ_ROOT=$GOPATH/src/github.com/hyperhq

if [ ! -d $HYPERHQ_ROOT ]; then
	mkdir -p $HYPERHQ_ROOT
fi


if [ -d $HYPERHQ_ROOT/runv ]; then
	echo "runv git repo already exist"
else
	git clone https://github.com/hyperhq/runv.git $HYPERHQ_ROOT/runv
fi

if [ -d $HYPERHQ_ROOT/hyperd ]; then
	echo "hyperd git repo already exist"
else
	git clone https://github.com/hyperhq/hyperd.git $HYPERHQ_ROOT/hyperd
	# make and install
	cd $HYPERHQ_ROOT/hyperd
	./autogen.sh && ./configure --prefix=/usr && make && make install

	cat >/etc/hyper/config <<EOF
Kernel=/var/lib/hyper/kernel
Initrd=/var/lib/hyper/hyper-initrd.img
gRPCHost=127.0.0.1:22318
EOF

fi

if [ -d $HYPERHQ_ROOT/hyperstart ]; then
	echo "hyperstart git repo already exist"
else
	git clone https://github.com/hyperhq/hyperstart.git $HYPERHQ_ROOT/hyperstart
	cd $HYPERHQ_ROOT/hyperstart
	./autogen.sh && ./configure && make && /bin/cp build/hyper-initrd.img build/kernel /var/lib/hyper/
fi

((hyperd --v=3 2>&1 | tee $HOME/log/hyperd.log)&)

