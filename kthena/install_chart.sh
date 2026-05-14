#!/bin/bash

INSTALL_ROUTER=true
INSTALL_CONTROLLER=true
COMPONENT_SPECIFIED=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -r, --router-only       Install router only"
    echo "  -c, --controller-only   Install controller manager only"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "By default, both router and controller manager are installed."
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--router-only)
            if [ "$COMPONENT_SPECIFIED" = true ]; then
                echo "Error: cannot specify both --router-only and --controller-only"
                exit 1
            fi
            INSTALL_ROUTER=true
            INSTALL_CONTROLLER=false
            COMPONENT_SPECIFIED=true
            shift
            ;;
        -c|--controller-only)
            if [ "$COMPONENT_SPECIFIED" = true ]; then
                echo "Error: cannot specify both --router-only and --controller-only"
                exit 1
            fi
            INSTALL_ROUTER=false
            INSTALL_CONTROLLER=true
            COMPONENT_SPECIFIED=true
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
    --set router.enabled=$INSTALL_ROUTER \
    --set workload.enabled=$INSTALL_CONTROLLER
