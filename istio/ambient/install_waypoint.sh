#!/bin/bash

# add waypoint
istioctl x waypoint apply --service-account default

# delete waypoint
istioctl x waypoint delete --service-account default