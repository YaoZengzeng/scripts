#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_claims>"
  exit 1
fi

COUNT=$1

for ((i=1; i<=COUNT; i++))
do
  CLAIM_NAME="sandbox-claim-$i"
  
  cat <<EOF | kubectl apply -f -
apiVersion: extensions.agents.x-k8s.io/v1alpha1
kind: SandboxClaim
metadata:
  name: $CLAIM_NAME
  namespace: default
spec:
  sandboxTemplateRef:
    name: secure-datascience-template
EOF

  echo "Created SandboxClaim: $CLAIM_NAME"
done
