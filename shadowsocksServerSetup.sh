#!/bin/sh

yum install -y python-setuptools && easy_install pip
pip install shadowsocks

ssserver -p 443 -k password -m rc4-md5 -d start

