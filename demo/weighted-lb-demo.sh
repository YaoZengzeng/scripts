#!/bin/bash

function prompt {
  read # Wait for the user to press Enter
  local count=$#
  local i=1

  for str in "$@"; do
    if [ $i -lt $count ]; then
      echo "$str"
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

prompt "Kmesh, Istio and Bookinfo have been installed"

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

execute_command "kubectl get pods"

prompt "Apply weight-based routing" "Configure traffic routing to send 90% of requests to reviews v1 and 10% to reviews v2"

kubectl apply -f -<<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 90
    - destination:
        host: reviews
        subset: v2
      weight: 10
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

prompt "Confirm that roughly 90% of the traffic go to reviews v1"

execute_command 'kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"'

prompt "Cleanup"

execute_command "kubectl delete virtualservice reviews"

execute_command "kubectl delete destinationrules reviews"

execute_command "istioctl x waypoint delete reviews-svc-waypoint"

execute_command "kubectl label service reviews istio.io/use-waypoint-"

execute_command "kubectl label namespace default istio.io/dataplane-mode-"

