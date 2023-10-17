#!/bin/bash

kind create cluster

# 指定特定镜像
# kind create cluster --image=kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72

# kind不同版本k8s列表：https://github.com/kubernetes-sigs/kind/releases

# 当以containerd作为运行时时，拉取镜像跳过https认证
# 在/etc/containerd/config.toml末尾添加以下内容：
# [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-cbu.huawei.com".tls]
#   insecure_skip_verify = true
