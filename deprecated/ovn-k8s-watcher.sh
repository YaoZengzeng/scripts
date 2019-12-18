#!/bin/bash

ovn-k8s-watcher \
  --overlay \
  --pidfile \
  --log-file \
  -vfile:info \
  -vconsole:emer \
  --detach

