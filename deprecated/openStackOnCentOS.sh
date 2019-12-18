#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

function kube::util::setup_openstack() {
	echo "Start $FUNCNAME"
	
	yum install -y centos-release-openstack-mitaka epel-release
	yum update -y
	yum install -y openstack-packstack

	packstack --gen-answer-file=/root/packstack_answer_file.txt

	sed -i 's/CONFIG_PROVISION_DEMO=y/CONFIG_PROVISION_DEMO=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_SWIFT_INSTALL=y/CONFIG_SWIFT_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_NEUTRON_METERING_AGENT_INSTALL=n/CONFIG_NEUTRON_METERING_AGENT_INSTALL=y/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_NAGIOS_INSTALL=y/CONFIG_NAGIOS_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_KEYSTONE_ADMIN_PW=.*/CONFIG_KEYSTONE_ADMIN_PW=admin/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_KEYSTONE_DEMO_PW=.*/CONFIG_KEYSTONE_DEMO_PW=demo/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_LBAAS_INSTALL=n/CONFIG_LBAAS_INSTALL=y/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_NEUTRON_FWAAS=n/CONFIG_NEUTRON_FWAAS=y/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_NOVA_INSTALL=y/CONFIG_NOVA_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_CEILOMETER_INSTALL=y/CONFIG_CEILOMETER_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_AODH_INSTALL=y/CONFIG_AODH_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_GNOCCHI_INSTALL=y/CONFIG_GNOCCHI_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_GLANCE_INSTALL=y/CONFIG_GLANCE_INSTALL=n/g' /root/packstack_answer_file.txt
	sed -i 's/CONFIG_USE_EPEL=n/CONFIG_USE_EPEL=y/g' /root/packstack_answer_file.txt

	# Install OpenStack
	packstack --answer-file=/root/packstack_answer_file.txt

	## Create external network
	source /root/keystonerc_admin
	## Make sure there is no network named br-ex, clean all resource
	kube::util::clean_neutron_resource "demo"
	kube::util::clean_neutron_resource "admin"
	
	neutron net-create --router:external br-ex
	neutron subnet-create br-ex 58.215.33.0/24
	sed -i 's/#dns_domain = openstacklocal/dns_domain = hypernetes/g' /etc/neutron/neutron.conf
	sed -i 's/#extension_drivers.*/extension_drivers = port_security,dns/g' /etc/neutron/plugins/ml2/ml2_conf.ini
	systemctl restart neutron-server
}

# will purge all resourses under tenant admin and demo
function kube::util::clean_neutron_resource() {
	local tenant_name=$1
	local tenant_id=`keystone tenant-list 2>/dev/null | grep ${tenant_name} | awk '{print $2}'`
	if [ "${tenant_id}" != "" ]; then
		neutron purge ${tenant_id}
	fi
}

# Set up OpenStack
kube::util::setup_openstack
