#/bin/bash

# --image-repository以阿里云作为源时，指定为"registry.aliyuncs.com/google_containers"
kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version=1.21.1 --image-repository=registry-cbu.huawei.com/yaozengzeng

kubectl taint nodes --all node-role.kubernetes.io/master-

# 查看日志
# journalctl -xeu kubelet

# 修改containerd配置，pause image其实在containerd的配置中指定
# 首先生成默认配置

# containerd config default > /etc/containerd/config.toml 

# 再修改sandbox_image为对应配置

# 加入节点
# kubeadm join 10.0.2.15:6443 --token wa8k2h.tjpmhvw3okoeoau9 --discovery-token-ca-cert-hash sha256:c5ca3446ad90988bc943af5785b24e727536956d68a1a44c8d1578056d43b6b9

# 删除集群
# kubeadm reset

# 移除集群中的某个节点
# kubectl delete node n2
