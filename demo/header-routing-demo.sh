#!/bin/bash

function prompt {
  read # Wait for the user to press Enter
  local count=$#
  local i=1

  for str in "$@"; do
    if [ $i -lt $count ]; then
      echo -e "$str"
    else
      echo -n "$str"
    fi
    ((i++))
  done

  read # Wait for the user to press Enter

  echo ""
}

function execute_command {
  echo "$1"
  eval "$1"
  echo ""
}

clear

prompt "Demo of Kmesh L7 Header Routing\n" "Kmesh, Istio and Bookinfo have been installed"

execute_command "kubectl get pods --all-namespaces"

prompt "Use Kmesh manage default namespace"

execute_command "kubectl label namespace default istio.io/dataplane-mode=Kmesh"

execute_command "kubectl get namespace -L istio.io/dataplane-mode"

prompt "Test bookinfo works as expected"

execute_command 'kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"'

prompt "Deploy a waypoint for reviews service"

execute_command "istioctl x waypoint apply -n default --name reviews-svc-waypoint"

execute_command "kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint"

execute_command "kubectl get gateways.gateway.networking.k8s.io"

prompt "Replace the waypoint image with Kmesh customized image"

execute_command "kubectl annotate gateway reviews-svc-waypoint sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest"

execute_command "watch kubectl get pods"

prompt "Apply header routing based on header end-user" "For end user jason, it will access service reviews v2 and the rest of users will access the reviews v1"

kubectl apply -f -<<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
EOF

execute_command "kubectl get vs reviews -oyaml"

prompt "Cleanup"

execute_command "kubectl delete virtualservice reviews"

execute_command "kubectl delete destinationrules reviews"

execute_command "istioctl x waypoint delete reviews-svc-waypoint"

execute_command "kubectl label service reviews istio.io/use-waypoint-"

execute_command "kubectl label namespace default istio.io/dataplane-mode-"

