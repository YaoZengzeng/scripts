#!/bin/bash

# https://github.com/kubernetes-sigs/agent-sandbox/releases
export VERSION="v0.1.1"

ACTION="apply"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -u, --uninstall    Uninstall agent-sandbox components"
    echo "  -h, --help         Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--uninstall)
            ACTION="delete"
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

echo "Performing ${ACTION} for agent-sandbox ${VERSION}..."

# To install/uninstall the core components:
kubectl ${ACTION} -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/${VERSION}/manifest.yaml

# To install/uninstall the extensions components:
kubectl ${ACTION} -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/${VERSION}/extensions.yaml
