#!/bin/bash

wget https://github.com/j178/chatgpt/releases/download/v1.2.0/chatgpt_Linux_x86_64.tar.gz

tar -xzvf chatgpt_Linux_x86_64.tar.gz

mv chatgpt /usr/local/bin

rm chatgpt_Linux_x86_64.tar.gz README.md

mkdir -p /root/.config/chatgpt

cp config.json /root/.config/chatgpt

