#!/bin/bash

sysctl -w fs.inotify.max_user_watches=10000000
sysctl -w fs.inotify.max_user_instances=10000000
