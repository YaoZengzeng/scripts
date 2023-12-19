#!/bin/bash

# 定义定时器
timer=5

# 循环执行
while true; do
  # 获取所有Pods
  pods=$(kubectl get pods --all-namespaces -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}")

  # 遍历所有Pods
  for pod in $pods; do
    # 检查前缀是否为"nginx"
    if [[ $pod == nginx5* ]]; then
      # 删除Pod
      kubectl delete pod $pod --namespace default
    fi
  done

  # 等待定时器
  sleep $timer
done
