#!/bin/bash

INSTALL_CONTROLLER=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -a, --all       Install both router and controller (default: only router)"
    echo "  -h, --help      Display this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            INSTALL_CONTROLLER=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

helm install test-release /root/kthena/charts/kthena --namespace kthena-system --create-namespace \
    --set workload.enabled=$INSTALL_CONTROLLER
