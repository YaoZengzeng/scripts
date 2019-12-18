#!/bin/bash
	
cd $GOPATH/src/github.com/hyperhq/kubestack && make && make install

## Configure KubeStack
source /root/keystonerc_admin
EXT_NET_ID=$(neutron net-show br-ex | awk '/ id /{print $4}')
rm -rf /etc/kubestack
mkdir /etc/kubestack/
cat > /etc/kubestack/kubestack.conf <<EOF
[Global]
auth-url = $OS_AUTH_URL
username = admin
password = admin
tenant-name = admin
region = RegionOne
ext-net-id = ${EXT_NET_ID}

[LoadBalancer]
create-monitor = yes
monitor-delay = 1m
monitor-timeout = 30s
monitor-max-retries = 3

[Plugin]
plugin-name = ovs
EOF

	cat > /usr/lib/systemd/system/kubestack.service <<EOF
[Unit]
Description=OpenStack Network Provider for Hypernetes
After=syslog.target network.target openvswitch.service
Requires=openvswitch.service

[Service]
ExecStart=/usr/local/bin/kubestack \
  -logtostderr=false -v=4 \
  -port=127.0.0.1:4237 \
  -log_dir=/var/log/kubestack \
  -conf=/etc/kubestack/kubestack.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

rm -rf /var/log/kubestack
mkdir -p /var/log/kubestack
systemctl enable kubestack.service
systemctl daemon-reload
systemctl start kubestack.service

