#!/bin/bash

# install sleep first

kubectl exec deploy/sleep -- curl -s http://productpage:9080/productpage  | grep reviews-v.-

