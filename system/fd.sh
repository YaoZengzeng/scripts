#!/bin/bash

sysctl -w fs.inotify.max_user_watches=10000000
sysctl -w fs.inotify.max_user_instances=10000000

# To make the changes persistent, edit the file `/etc/sysctl.conf` and add these lines above.
