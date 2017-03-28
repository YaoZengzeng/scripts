#!/bin/bash
set -o errexit

#install essential tools
yum install -y git cmake gcc g++ autoconf automake device-mapper-devel sqlite-devel pcre-devel libsepol-devel libselinux-devel systemd-container-devel automake autoconf gcc make glibc-devel glibc-devel.i686 libvirt-devel

yum install -y libvirt

yum install -y qemu.x86_64

yum install -y qemu-kvm.x86_64

cat >> /etc/libvirt/qemu.conf <<EOF
user = "root"
group = "root"
clear_emulator_capabilities = 0
EOF

systemctl restart libvirtd
systemctl enable libvirtd

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

	mkdir /etc/hyper
	touch /etc/hyper/config

	cat > /etc/hyper/config <<EOF
Kernel=/var/lib/hyper/kernel
Initrd=/var/lib/hyper/hyper-initrd.img
DisableIptables=true
StorageDriver=devicemapper
Hypervisor=libvirt
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

