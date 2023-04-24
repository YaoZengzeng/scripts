IMG ?= registry-cbu.huawei.com/yaozengzeng/multiport-server:0.1.0

docker-build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o multi-server main.go
	docker build -t ${IMG} .

docker-push:
	docker push ${IMG}

build-server:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o multi-server main.go
