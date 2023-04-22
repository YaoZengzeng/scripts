#!/bin/bash

SOURCE_HOST="1.1.1.1"
DST_HOST="2.2.2.2"

iptables -t nat -D SHADOWSOCKS -d $DST_HOST -j RETURN

iptables -t nat -D SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -D SHADOWSOCKS -d 240.0.0.0/4 -j RETURN

iptables -t nat -D SHADOWSOCKS -d $SOURCE_HOST -j RETURN
iptables -t nat -D SHADOWSOCKS -d 8.8.8.8 -j RETURN

iptables -t nat -D SHADOWSOCKS -p tcp -j REDIRECT --to-ports 1080

iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
iptables -t mangle -D OUTPUT -j SHADOWSOCKS

iptables -t nat -X SHADOWSOCKS
iptables -t mangle -X SHADOWSOCKS
