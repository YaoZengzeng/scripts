#### 自定义sidecar日志级别

```sh
// 添加特定的annotations
  template:
    metadata:
      annotations:
        "sidecar.istio.io/logLevel": debug # 可选: trace, debug, info, warning, error, critical, off
        "sidecar.istio.io/componentLogLevel": ext_authz:trace,filter:debug #完整的列表查看 https://github.com/envoyproxy/envoy/blob/69bb7bc6888741b2bad0ea1eec37d00f677eb85f//source/common/common/logger.h

// 通过annotations对Proxy进行配置，更完整的列表：https://help.aliyun.com/document_detail/358835.html

// 使用istioctl动态调整
istioctl proxy-config log productpage-v1-7668cb67cc-86q8l --level trace

// 通过curl命令调整envoy日志级别
kubectl exec nginx-istio-waypoint-bf7f745dd-rmgln -- curl -XPOST 127.0.0.1:15000/logging?level=trace
```
