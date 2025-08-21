#!/bin/bash

cd /root/orion

docker build -f docker/Dockerfile -t ghcr.io/yaozengzeng/orion:latest .
