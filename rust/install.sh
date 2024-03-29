#!/bin/bash

apt-get update

sudo apt install -y git gcc g++ make cmake pkg-config llvm-dev libclang-dev clang protobuf-compiler

curl https://sh.rustup.rs -sSf | sh

