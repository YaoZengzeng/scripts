#!/bin/sh

# Install necessary utilties
yum -y install wget gcc make python-devel openssl-devel kernel-devel graphviz kernel-debug-devel autoconf automake libtool

git clone https://github.com/openvswitch/ovs.git
cd ovs

# Bootstrapping
./boot.sh

# Configuring
./configure

# Building
make && make install

# Starting
# Before ovsdb-server itself can started, configure a database that is can use
mkdir -p /usr/local/etc/openvswitch
ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema

# Configure ovsdb-server to use database created above
# to listen on a Unix domain socket, to connect to any
# managers specified in the database itself, and to use
# the SSL configuration in the databasae
mkdir -p /usr/local/var/run/openvswitch
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
	--remote=db:Open_vSwitch,Open_vSwitch,manager_options \
	--pidfile --detach --log-file

# Initialize the database using ovs-vsctl
ovs-vsctl --no-wait init

# Start the main Open vSwitch daemon, telling it to connect
# to the same Unix domain socket
ovs-vswitchd --pidfile --detach --log-file

# Validating
# ovs-vsctl add-br br0
# ovs-vsctl add-port br0

