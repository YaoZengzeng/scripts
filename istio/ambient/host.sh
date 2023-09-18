#!/bin/bash

kubectl create ns mesh

kubectl label namespace mesh istio.io/dataplane-mode=ambient

istioctl x waypoint apply --service-account default -n mesh
