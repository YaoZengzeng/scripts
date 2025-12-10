#!/bin/bash

helm install test-release /root/kthena/charts/kthena --namespace kthena-system --create-namespace
