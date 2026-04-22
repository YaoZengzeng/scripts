#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Install NVIDIA Driver, CUDA Toolkit, and NVIDIA Container Toolkit (nvidia-docker)
# on Ubuntu 22.04, then verify everything works.
#
# Usage:
#   sudo ./cuda.sh [all|driver|cuda|nvidia-docker|verify]
#
# Environment variables:
#   NVIDIA_DRIVER_VERSION  (default: 570)       driver branch
#   CUDA_VERSION           (default: 12-8)      CUDA toolkit version (dash-separated)
#   SKIP_REBOOT_CHECK      (default: false)      set "true" to skip reboot prompt

set -e
set -o pipefail

# --------------------------------------------------------------------------- #
# Colour helpers
# --------------------------------------------------------------------------- #
COLOR_RESET=$'\e[0m'
COLOR_GREEN=$'\e[32m'
COLOR_RED=$'\e[31m'
COLOR_YELLOW=$'\e[33m'

log_success() { echo "${COLOR_GREEN}✅ $*${COLOR_RESET}"; }
log_error()   { echo "${COLOR_RED}❌ $*${COLOR_RESET}" >&2; }
log_info()    { echo "ℹ️  $*"; }
log_warn()    { echo "${COLOR_YELLOW}⚠️  $*${COLOR_RESET}"; }

# --------------------------------------------------------------------------- #
# Pre-flight
# --------------------------------------------------------------------------- #
if [[ $EUID -ne 0 ]]; then
  log_error "This script must be run as root (sudo)."
  exit 1
fi

. /etc/os-release 2>/dev/null || true
if [[ "${ID}" != "ubuntu" ]]; then
  log_warn "This script is designed for Ubuntu 22.04. Detected: ${PRETTY_NAME:-unknown}"
fi

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
MODE=${1:-all}
NVIDIA_DRIVER_VERSION=${NVIDIA_DRIVER_VERSION:-570}
CUDA_VERSION=${CUDA_VERSION:-"12-8"}
SKIP_REBOOT_CHECK=${SKIP_REBOOT_CHECK:-"false"}

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
apt_update_once() {
  if [[ -z "${_APT_UPDATED:-}" ]]; then
    apt-get update -qq
    _APT_UPDATED=1
  fi
}

need_reboot() {
  if [[ "${SKIP_REBOOT_CHECK}" == "true" ]]; then
    return
  fi
  log_warn "A reboot is recommended before continuing."
  log_warn "After reboot, re-run:  sudo ./cuda.sh <next-step>"
}

# --------------------------------------------------------------------------- #
# Step 1: Install NVIDIA Driver
# --------------------------------------------------------------------------- #
install_driver() {
  log_info "=== Installing NVIDIA Driver (branch: ${NVIDIA_DRIVER_VERSION}) ==="
  apt_update_once

  apt-get install -y -qq software-properties-common ubuntu-drivers-common

  log_info "Installing nvidia-driver-${NVIDIA_DRIVER_VERSION}..."
  apt-get install -y "nvidia-driver-${NVIDIA_DRIVER_VERSION}"

  # Load the driver module if possible (may fail if nouveau is still active)
  modprobe nvidia 2>/dev/null || true

  if nvidia-smi &>/dev/null; then
    log_success "NVIDIA driver loaded."
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
  else
    log_warn "nvidia-smi not yet responding — a reboot is required."
    need_reboot
  fi
}

# --------------------------------------------------------------------------- #
# Step 2: Install CUDA Toolkit
# --------------------------------------------------------------------------- #
install_cuda() {
  log_info "=== Installing CUDA Toolkit (cuda-toolkit-${CUDA_VERSION}) ==="
  apt_update_once

  # Add the NVIDIA CUDA repository (ubuntu2204 / x86_64)
  local arch
  arch=$(dpkg --print-architecture)  # amd64
  local keyring="/usr/share/keyrings/cuda-archive-keyring.gpg"
  local repo_url="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/${arch/amd64/x86_64}"

  if [[ ! -f "${keyring}" ]]; then
    log_info "Adding NVIDIA CUDA repository..."
    wget -qO- "${repo_url}/3bf863cc.pub" | gpg --dearmor -o "${keyring}"
    echo "deb [signed-by=${keyring}] ${repo_url}/ /" \
      > /etc/apt/sources.list.d/cuda-ubuntu2204.list
    apt-get update -qq
    _APT_UPDATED=1
  fi

  log_info "Installing cuda-toolkit-${CUDA_VERSION}..."
  apt-get install -y "cuda-toolkit-${CUDA_VERSION}"

  # Set up environment for current session
  local cuda_home="/usr/local/cuda"
  if [[ -d "${cuda_home}" ]]; then
    export PATH="${cuda_home}/bin:${PATH}"
    export LD_LIBRARY_PATH="${cuda_home}/lib64:${LD_LIBRARY_PATH:-}"
  fi

  # Persist PATH for all users
  local profile_file="/etc/profile.d/cuda.sh"
  if [[ ! -f "${profile_file}" ]]; then
    cat > "${profile_file}" <<'EOF'
export PATH=/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
EOF
    log_info "Created ${profile_file} for persistent CUDA PATH."
  fi

  log_success "CUDA Toolkit installed."
}

# --------------------------------------------------------------------------- #
# Step 3: Install NVIDIA Container Toolkit (nvidia-docker)
# --------------------------------------------------------------------------- #
install_nvidia_docker() {
  log_info "=== Installing NVIDIA Container Toolkit ==="

  # Install Docker if not present
  if ! command -v docker &>/dev/null; then
    log_info "Docker not found — installing docker.io..."
    apt_update_once
    apt-get install -y -qq docker.io
    systemctl enable --now docker
    log_success "Docker installed."
  fi

  # Add NVIDIA Container Toolkit repository
  local keyring="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
  if [[ ! -f "${keyring}" ]]; then
    log_info "Adding NVIDIA Container Toolkit repository..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
      | gpg --dearmor -o "${keyring}"
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
      | sed "s#deb https://#deb [signed-by=${keyring}] https://#g" \
      > /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt-get update -qq
    _APT_UPDATED=1
  fi

  log_info "Installing nvidia-container-toolkit..."
  apt-get install -y -qq nvidia-container-toolkit

  # Configure Docker runtime
  log_info "Configuring Docker to use NVIDIA runtime..."
  nvidia-ctk runtime configure --runtime=docker

  systemctl restart docker
  log_success "NVIDIA Container Toolkit installed and Docker configured."
}

# --------------------------------------------------------------------------- #
# Step 4: Verify Everything
# --------------------------------------------------------------------------- #
verify() {
  log_info "=== Verification ==="
  local failed=0

  # 1) nvidia-smi
  log_info "--- nvidia-smi ---"
  if nvidia-smi; then
    log_success "nvidia-smi: OK"
  else
    log_error "nvidia-smi: FAILED"
    failed=1
  fi
  echo ""

  # 2) CUDA compiler
  log_info "--- nvcc ---"
  if command -v nvcc &>/dev/null; then
    nvcc --version | tail -1
    log_success "nvcc: OK"
  else
    # Try with full path
    if /usr/local/cuda/bin/nvcc --version &>/dev/null; then
      /usr/local/cuda/bin/nvcc --version | tail -1
      log_success "nvcc: OK (at /usr/local/cuda/bin/nvcc)"
    else
      log_error "nvcc: NOT FOUND"
      failed=1
    fi
  fi
  echo ""

  # 3) NVIDIA Container runtime
  log_info "--- nvidia-docker ---"
  if command -v nvidia-ctk &>/dev/null; then
    nvidia-ctk --version
    log_success "nvidia-ctk: OK"
  else
    log_error "nvidia-ctk: NOT FOUND"
    failed=1
  fi

  if command -v docker &>/dev/null; then
    log_info "Running: docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi"
    if docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi; then
      log_success "nvidia-docker GPU passthrough: OK"
    else
      log_error "nvidia-docker GPU passthrough: FAILED"
      failed=1
    fi
  else
    log_error "Docker: NOT FOUND"
    failed=1
  fi
  echo ""

  # 4) CUDA libraries
  log_info "--- CUDA libraries ---"
  if ldconfig -p | grep -q libcudart; then
    log_success "libcudart: found"
  else
    log_warn "libcudart: not in ldconfig (may need LD_LIBRARY_PATH)"
  fi

  if ldconfig -p | grep -q libnccl; then
    log_success "libnccl: found"
  else
    log_info "libnccl: not found (install separately if needed for multi-GPU)"
  fi
  echo ""

  # Summary
  if [[ ${failed} -eq 0 ]]; then
    log_success "=== All checks passed ==="
  else
    log_error "=== Some checks failed — review the output above ==="
    return 1
  fi
}

# --------------------------------------------------------------------------- #
# All: run in order
# --------------------------------------------------------------------------- #
install_all() {
  install_driver
  install_cuda
  install_nvidia_docker
  echo ""
  verify
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
case "${MODE}" in
  all)            install_all ;;
  driver)         install_driver ;;
  cuda)           install_cuda ;;
  nvidia-docker)  install_nvidia_docker ;;
  verify)         verify ;;
  *)
    log_error "Unknown mode: '${MODE}'"
    echo "Usage: sudo $0 [all|driver|cuda|nvidia-docker|verify]"
    echo ""
    echo "  all            Install driver + CUDA + nvidia-docker, then verify"
    echo "  driver         Install NVIDIA GPU driver only"
    echo "  cuda           Install CUDA Toolkit only"
    echo "  nvidia-docker  Install NVIDIA Container Toolkit + Docker"
    echo "  verify         Verify all components are working"
    exit 1
    ;;
esac