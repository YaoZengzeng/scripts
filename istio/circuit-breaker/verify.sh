#!/bin/bash

# Not work in ambient yet?

kubectl exec deploy/fortio-deploy --  /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
