#!/bin/bash

#!/bin/bash

LOCAL_PORT=4000

export POD_NAME=$(kubectl get pods -l "app=litellm" -o jsonpath="{.items[0].metadata.name}")

export CONTAINER_PORT=$(kubectl get pod $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")

echo "Visit http://127.0.0.1:$LOCAL_PORT to use your litellm"

kubectl port-forward $POD_NAME $LOCAL_PORT:$CONTAINER_PORT
