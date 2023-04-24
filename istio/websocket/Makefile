IMG ?= registry-cbu.huawei.com/yaozengzeng/websocket-server:0.1.0

docker-build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o websocket-server server.go
	docker build -t ${IMG} .

docker-push:
	docker push ${IMG}

build-client:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o client-load client-load.go

build-server:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o websocket-server server.go

