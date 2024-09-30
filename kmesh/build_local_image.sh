#!/bin/bash

cd /root/kmesh

HUB="localhost:5000" TAG="latest" make docker.push

cp ./kmeshctl /usr/local/bin
