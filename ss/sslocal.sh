#!/bin/bash


IP="1.1.1.1"
sslocal -b "127.0.0.1:1080" --protocol redir -s "$IP:3389" -m "aes-256-gcm" -k "password" --tcp-redir "redirect" --udp-redir "tproxy" -v
