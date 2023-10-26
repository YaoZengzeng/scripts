#!/bin/bash

kubectl exec  deploy/sleep -- curl -s -v http://nginx.sleep
