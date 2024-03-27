#!/bin/bash

kubectl exec "$1"  -- curl -XPOST 127.0.0.1:15000/logging?level=trace
