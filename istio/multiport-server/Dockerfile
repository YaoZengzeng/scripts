FROM registry-cbu.huawei.com/yaozengzeng/kube-proxy:v1.21.1

WORKDIR /

COPY multi-server .

USER 0:0

ENTRYPOINT ["/multi-server"]
