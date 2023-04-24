#!/bin/sh

kubectl port-forward --address 0.0.0.0 deploy/webapp 8080:8080
