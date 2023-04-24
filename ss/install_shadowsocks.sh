#!/bin/sh

wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.15.3/shadowsocks-v1.15.3.x86_64-unknown-linux-gnu.tar.xz

tar -xvJf shadowsocks-v1.15.3.x86_64-unknown-linux-gnu.tar.xz

cp sslocal /usr/local/bin
cp ssserver /usr/local/bin
