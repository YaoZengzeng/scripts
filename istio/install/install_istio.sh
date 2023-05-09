#!/bin/bash

istioctl x precheck

istioctl install --set profile=demo -y

kubectl label namespace default istio-injection=enabled
