#!/bin/bash

NGINX_HOST="10.102.72.156"

kubectl exec -n sleep deploy/sleep -- curl -s -v http://$NGINX_HOST
