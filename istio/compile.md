### istiod编译

```sh
make build

// 只编译pilot-discovery和pilot-agent
BUILD_WITH_CONTAINER=1 STANDARD_BINARIES=./pilot/cmd/pilot-discovery make build

// 进行go fmt
BUILD_WITH_CONTAINER=1 make fmt
```

### 构建pilot镜像

```sh
docker commit --change='ENTRYPOINT ["/usr/local/bin/pilot-discovery"]' 2ce2657b752b istio/demo-pilot:1.13.3
```

### 构建proxyv2镜像

```sh
docker commit --change='ENTRYPOINT ["/usr/local/bin/pilot-agent"]' e64f13c69a07  istio/demo-proxyv2:1.13.3
```

### istio-proxy编译

```sh
BUILD_WITH_CONTAINER=1 make build_envoy
```

### envoy编译

```sh
// 先构建一个容器，保持常驻
docker run --name envoy_build -v /root/data:/root/data registry-cbu.huawei.com/istio/istio-proxy-bulid-tool:1.8.4 sleep 100000000000

// 再利用exec命令进行编译
docker exec -it envoy_build bash -c "export BAZEL_BUILD_ARGS=--override_repository=envoy=/root/data/envoy;cd /root/data/proxy;make build_envoy"

// 容器内路径
docker cp envoy_build:/root/.cache/bazel/_bazel_root/0b2f5c7fac4b02c7efd0f9f5b724b1fe/execroot/io_istio_proxy/bazel-out/k8-opt/bin/src/envoy/envoy .


// 1.13 envoy编译
docker run -it --name envoy_build -v /root/data:/root/data  registry-cbu.huawei.com/yaozengzeng/envoy-build:13.0.0 sleep 10000000

docker run -it --name envoy_build -v /root/data:/root/data registry-cbu.huawei.com/yaozengzeng/envoy-build:1.13.3 sleep 10000000

docker run -it --name envoy_build --network host -v "/etc/ssl/certs":"/etc/ssl/certs" -v "/usr/local/share/ca-certificates":"/usr/local/share/ca-certificates" -v /root/data:/root/data  registry-cbu.huawei.com/yaozengzeng/envoy-build:1.13.3 sleep 10000000

// 再利用exec命令进行编译
docker exec -it envoy_build bash -c "export BAZEL_BUILD_ARGS=--override_repository=envoy=/root/data/envoy;cd /root/data/proxy;make build_envoy"

// 容器内路径
docker cp envoy_build:/home/.cache/bazel/_bazel_root/0b2f5c7fac4b02c7efd0f9f5b724b1fe/execroot/io_istio_proxy/bazel-out/k8-opt/bin/src/envoy/envoy .
```
