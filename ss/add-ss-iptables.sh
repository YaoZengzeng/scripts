#!/bin/bash

iptables -t nat -N SHADOWSOCKS
iptables -t mangle -N SHADOWSOCKS

SOURCE_HOST="1.1.1.1"
DST_HOST="2.2.2.2"

iptables -t nat -A SHADOWSOCKS -d  $DST_HOST -j RETURN

iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN

iptables -t nat -A SHADOWSOCKS -d $SOURCE_HOST -j RETURN
iptables -t nat -A SHADOWSOCKS -d 8.8.8.8 -j RETURN

iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports 1080

iptables -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
iptables -t mangle -A OUTPUT -j SHADOWSOCKS
