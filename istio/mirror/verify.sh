#!/bin/bash

kubectl exec deploy/sleep -c sleep -- curl -sS http://httpbin:8000/headers
