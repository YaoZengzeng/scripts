#!/bin/bash

curl -fsSL -o get-egctl.sh https://gateway.envoyproxy.io/get-egctl.sh

chmod +x get-egctl.sh

# get help info of the
bash get-egctl.sh --help

# install the latest development version of egctl
bash VERSION=latest get-egctl.sh

rm -rf get-egctl.sh
