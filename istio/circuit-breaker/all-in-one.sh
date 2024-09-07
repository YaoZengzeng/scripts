#!/bin/bash

bash ../fortio/all-in-one.sh

bash ../httpbin/all-in-one.sh

bash ../waypoint/add-svc-waypoint.sh httpbin

kubectl apply -f dr.yaml
