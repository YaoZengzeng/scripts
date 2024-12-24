#!/bin/bash

curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz

sudo tar -C /usr -xzf ollama-linux-amd64.tgz

rm -rf ollama-linux-amd64.tgz
