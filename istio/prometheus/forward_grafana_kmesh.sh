#!/bin/bash

kubectl port-forward --address 0.0.0.0 svc/grafana 3000:3000 -n kmesh-system
