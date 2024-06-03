#!/bin/bash

kind create cluster --image kindest/node:v1.30.0@sha256:047357ac0cfea04663786a612ba1eaba9702bef25227a794b52890dd8bcd692e --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ambient
nodes:
- role: control-plane
# - role: worker
EOF

# 指定特定镜像
# kind create cluster --image=kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72

# kind不同版本k8s列表：https://github.com/kubernetes-sigs/kind/releases

# 当以containerd作为运行时时，拉取镜像跳过https认证
# 在/etc/containerd/config.toml末尾添加以下内容：
# [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-cbu.huawei.com".tls]
#   insecure_skip_verify = true


kubectl cluster-info --context kind-ambient

