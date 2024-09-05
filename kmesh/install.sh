#!/bin/bash

local_image=true

if "$local_image"; then
	helm install kmesh /root/kmesh/deploy/charts/kmesh-helm -n kmesh-system --create-namespace --set deploy.kmesh.image.repository=localhost:5000/kmesh
else
	helm install kmesh /root/kmesh/deploy/charts/kmesh-helm -n kmesh-system --create-namespace
fi
