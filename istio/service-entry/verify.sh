#!/bin/bash

kubectl exec deploy/sleep -- curl -v http://240.240.240.255:80/productpage
