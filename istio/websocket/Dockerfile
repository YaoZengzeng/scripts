FROM registry-cbu.huawei.com/yaozengzeng/kube-proxy:v1.21.1

WORKDIR /

COPY websocket-server .

USER 0:0

ENTRYPOINT ["/websocket-server"]
