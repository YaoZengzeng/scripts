#!/bin/bash

istioctl install --set profile=ambient --set values.cni.ambient.redirectMode="ebpf"

