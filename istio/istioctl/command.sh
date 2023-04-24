#!/bin/sh

# 查看listener
istioctl -n istio-system proxy-config listener deploy/istio-ingressgateway

# 查看路由
istioctl proxy-config route deploy/istio-ingressgateway -o json --name http.8080  -n istio-system
