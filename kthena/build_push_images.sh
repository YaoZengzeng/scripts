#!/bin/bash

set -e

HUB="ghcr.io/yaozengzeng"
COMPONENTS=()

usage() {
  echo "Usage: $0 [OPTIONS] [COMPONENT...]"
  echo ""
  echo "Components:"
  echo "  router      Build and push kthena-router"
  echo "  controller  Build and push kthena-controller-manager"
  echo "  runtime     Build and push runtime"
  echo "  downloader  Build and push downloader"
  echo "  all         Build and push all components"
  echo ""
  echo "Options:"
  echo "  -h, --help  Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 router"
  echo "  $0 router runtime"
  echo "  $0 all"
  exit 0
}

if [[ $# -eq 0 ]]; then
  usage
fi

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage ;;
    router|controller|runtime|downloader) COMPONENTS+=("$arg") ;;
    all) COMPONENTS=("router" "controller" "runtime" "downloader") ;;
    *) echo "Unknown component: $arg"; usage ;;
  esac
done

cd /root/kthena
export HUB="$HUB"

build_push() {
  local component="$1"
  local image="$2"
  echo "==> Building $component..."
  make "docker-build-${component}"
  echo "==> Pushing ${image}..."
  docker push "${image}"
}

for component in "${COMPONENTS[@]}"; do
  case "$component" in
    router)     build_push router     "${HUB}/kthena-router:latest" ;;
    controller) build_push controller "${HUB}/kthena-controller-manager:latest" ;;
    runtime)    build_push runtime    "${HUB}/runtime:latest" ;;
    downloader) build_push downloader "${HUB}/downloader:latest" ;;
  esac
done

echo "==> Done."
