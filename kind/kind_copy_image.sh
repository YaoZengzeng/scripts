#!/bin/bash

# Show usage information
show_usage() {
    echo "Usage: $0 <image-name> [kind-cluster-name]"
    echo "Example: $0 ghcr.io/kmesh-net/kmesh:latest ambient"
    echo "Example: $0 my-image:tag my-cluster"
    exit 1
}

# Check if image name is provided
if [ -z "$1" ]; then
    echo "Error: Please provide image name"
    show_usage
fi

IMAGE_NAME="$1"
KIND_NAME="${2:-ambient}"  # If second argument is not provided, default to 'ambient'

kind load docker-image "$IMAGE_NAME" --name "$KIND_NAME"
