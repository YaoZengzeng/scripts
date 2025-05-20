#!/bin/bash

# temporary modifications

# sysctl -w fs.inotify.max_user_watches=10000000
# sysctl -w fs.inotify.max_user_instances=10000000

# make the changes persistent

echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
echo "fs.inotify.max_user_instances = 512" >> /etc/sysctl.conf
