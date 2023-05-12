#!/bin/bash

kubectl exec deploy/sleep -- curl -v auto.internal
