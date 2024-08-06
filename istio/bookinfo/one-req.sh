#!/bin/bash

kubectl exec deploy/sleep -- sh -c "curl -s http://productpage:9080/productpage | grep reviews-v.-"
