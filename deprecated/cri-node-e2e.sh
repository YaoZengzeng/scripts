#/bin/sh

cd $GOPATH/src/k8s.io/kubernetes

make test-e2e-node RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT=unix:///var/run/pouchcri.sock IMAGE_SERVICE_ENDPOINT=unix:///var/run/pouchcri.sock TEST_ARGS="--prepull-images=false"

