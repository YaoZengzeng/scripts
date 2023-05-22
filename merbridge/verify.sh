#!/bin/bash

kubectl exec $(kubectl get po -l app=sleep -o=jsonpath='{..metadata.name}') -c sleep -- curl -s -v helloworld:5000/hello
