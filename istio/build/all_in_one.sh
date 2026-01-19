#!/bin/bash
set -e

# Default values
VERSION="1.27.5"
CLUSTER_NAME="kmesh-testing"

# Function to show usage
usage() {
    echo "Usage: $0 [version] [cluster_name]"
    echo "   or: $0 -v <version> -c <cluster_name>"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION      Specify the version (default: $VERSION)"
    echo "  -c, --cluster NAME         Specify the kind cluster name (default: $CLUSTER_NAME)"
    echo "  -h, --help                Show this message"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ "$1" == -* ]]; then
                echo "Unknown option: $1"
                usage
                exit 1
            fi
            # Positional arguments
            if [[ -z "$POS_V" ]]; then
                VERSION="$1"
                POS_V=1
            elif [[ -z "$POS_C" ]]; then
                CLUSTER_NAME="$1"
                POS_C=1
            else
                echo "Too many positional arguments: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==== Starting All-In-One Build & Deploy ===="
echo "Version: $VERSION"
echo "Cluster: $CLUSTER_NAME"
echo "Directory: $SCRIPT_DIR"
echo "==========================================="

echo "--> Step 1: Building Istio binaries (make.sh)"
chmod +x make.sh
./make.sh

echo "--> Step 2: Building Docker image (build.sh $VERSION)"
chmod +x build.sh
./build.sh "$VERSION"

echo "--> Step 3: Loading image into Kind (kind_copy.sh $VERSION $CLUSTER_NAME)"
chmod +x kind_copy.sh
./kind_copy.sh "$VERSION" "$CLUSTER_NAME"

echo "==== All steps completed successfully! ===="
