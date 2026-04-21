#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Vast.ai Host Setup Script
# Automates the host setup steps from https://cloud.vast.ai/host/setup/
#
# Usage:
#   sudo ./install.sh [all|driver|docker-storage|disable-autoupdate|network|vastai|test]
#
# Environment variables:
#   NVIDIA_DRIVER_VERSION  (default: 570)  NVIDIA driver branch to install
#   DOCKER_PARTITION       (optional)      e.g. /dev/sdb1 — if not set, skips XFS setup
#   PORT_RANGE_START       (default: 16384)
#   PORT_RANGE_END         (default: 32768)
#   VAST_API_KEY           (required for 'vastai' step)
#   VAST_MACHINE_ID        (required for 'test' step)
#   APT_MIRROR             (optional)      custom apt mirror for containers, e.g. mirror.yandex.ru

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

if ! grep -qi 'ubuntu' /etc/os-release 2>/dev/null; then
  log_warn "This script is designed for Ubuntu Server 20.04+. Detected a non-Ubuntu OS."
fi

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
MODE=${1:-all}
NVIDIA_DRIVER_VERSION=${NVIDIA_DRIVER_VERSION:-570}
DOCKER_PARTITION=${DOCKER_PARTITION:-""}
PORT_RANGE_START=${PORT_RANGE_START:-16384}
PORT_RANGE_END=${PORT_RANGE_END:-32768}
VAST_API_KEY=${VAST_API_KEY:-""}
VAST_MACHINE_ID=${VAST_MACHINE_ID:-""}
APT_MIRROR=${APT_MIRROR:-""}

# --------------------------------------------------------------------------- #
# Step 1: Install NVIDIA GPU Driver
# --------------------------------------------------------------------------- #
install_driver() {
  log_info "=== Installing NVIDIA Driver (branch: ${NVIDIA_DRIVER_VERSION}) ==="

  apt-get update -qq
  apt-get install -y -qq ubuntu-drivers-common

  # Install the driver using ubuntu-drivers with the specified version
  log_info "Installing nvidia-driver-${NVIDIA_DRIVER_VERSION}..."
  apt-get install -y "nvidia-driver-${NVIDIA_DRIVER_VERSION}"

  # Verify
  log_info "Verifying NVIDIA driver..."
  if nvidia-smi -q &>/dev/null; then
    log_success "NVIDIA driver installed and working."
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
  else
    log_warn "nvidia-smi not responding. A reboot may be required."
    log_info "Run: sudo reboot"
  fi
}

# --------------------------------------------------------------------------- #
# Step 2: Disable Auto Updates (prevent NVML mismatch)
# --------------------------------------------------------------------------- #
disable_autoupdate() {
  log_info "=== Disabling Automatic Updates ==="

  # Disable unattended-upgrades
  systemctl stop unattended-upgrades 2>/dev/null || true
  systemctl disable unattended-upgrades 2>/dev/null || true
  apt-get remove -y unattended-upgrades 2>/dev/null || true

  # Disable apt daily timers
  systemctl stop apt-daily.timer 2>/dev/null || true
  systemctl disable apt-daily.timer 2>/dev/null || true
  systemctl stop apt-daily-upgrade.timer 2>/dev/null || true
  systemctl disable apt-daily-upgrade.timer 2>/dev/null || true

  # Hold NVIDIA packages to prevent auto-upgrade
  if dpkg -l | grep -q "nvidia-driver-${NVIDIA_DRIVER_VERSION}"; then
    apt-mark hold "nvidia-driver-${NVIDIA_DRIVER_VERSION}"
    log_info "Pinned nvidia-driver-${NVIDIA_DRIVER_VERSION} to prevent upgrades."
  fi

  log_success "Auto updates disabled."
}

# --------------------------------------------------------------------------- #
# Step 3: Set up Docker Storage (XFS partition)
# --------------------------------------------------------------------------- #
setup_docker_storage() {
  log_info "=== Setting Up Docker Storage ==="

  if [[ -z "${DOCKER_PARTITION}" ]]; then
    log_info "DOCKER_PARTITION not set — skipping XFS setup."
    log_info "The Vast.ai installer will auto-detect the largest free partition"
    log_info "or fall back to a loopback device."
    return
  fi

  if [[ ! -b "${DOCKER_PARTITION}" ]]; then
    log_error "Block device '${DOCKER_PARTITION}' does not exist."
    exit 1
  fi

  log_info "Formatting ${DOCKER_PARTITION} as XFS..."
  mkfs.xfs -f "${DOCKER_PARTITION}"

  local uuid
  uuid=$(blkid -s UUID -o value "${DOCKER_PARTITION}")
  log_info "UUID: ${uuid}"

  mkdir -p /var/lib/docker

  # Add fstab entry if not already present
  if ! grep -q "${uuid}" /etc/fstab; then
    echo "UUID=${uuid} /var/lib/docker xfs rw,auto,pquota 0 0" >> /etc/fstab
    log_info "Added fstab entry."
  else
    log_info "fstab entry already exists."
  fi

  mount /var/lib/docker
  systemctl daemon-reload

  log_success "Docker storage mounted at /var/lib/docker (XFS)."
  df -h /var/lib/docker
}

# --------------------------------------------------------------------------- #
# Step 4: Handle AMD EPYC IOMMU (if applicable)
# --------------------------------------------------------------------------- #
fix_epyc_iommu() {
  if grep -qi 'epyc\|amd' /proc/cpuinfo 2>/dev/null; then
    log_info "=== AMD EPYC Detected — Checking IOMMU Settings ==="

    # Disable IOMMU to prevent NCCL issues with NVIDIA GPUs
    if grep -q 'iommu=off' /proc/cmdline; then
      log_info "IOMMU already disabled in kernel cmdline."
    else
      log_warn "AMD EPYC systems have a known NCCL compatibility issue with NVIDIA GPUs."
      log_warn "Consider adding 'amd_iommu=off iommu=off' to GRUB_CMDLINE_LINUX in /etc/default/grub"
      log_warn "Then run: sudo update-grub && sudo reboot"
    fi
  fi
}

# --------------------------------------------------------------------------- #
# Step 5: Network / Port Configuration
# --------------------------------------------------------------------------- #
setup_network() {
  log_info "=== Network & Port Configuration ==="

  local gpu_count
  gpu_count=$(nvidia-smi -L 2>/dev/null | wc -l || echo 0)
  local min_ports=$((gpu_count * 3))
  local recommended_ports=$((gpu_count * 100))
  local configured_ports=$(( PORT_RANGE_END - PORT_RANGE_START + 1 ))

  log_info "GPUs detected: ${gpu_count}"
  log_info "Port range: ${PORT_RANGE_START}-${PORT_RANGE_END} (${configured_ports} ports)"
  log_info "Minimum required: ${min_ports} ports (3 per GPU)"
  log_info "Recommended: ${recommended_ports} ports (100 per GPU)"

  if [[ ${configured_ports} -lt ${min_ports} ]]; then
    log_error "Port range too small. Need at least ${min_ports} ports for ${gpu_count} GPUs."
    exit 1
  fi

  # Write port range for the Vast.ai daemon
  mkdir -p /var/lib/vastai_kaalia
  printf '%s' "${PORT_RANGE_START}-${PORT_RANGE_END}" > /var/lib/vastai_kaalia/host_port_range
  log_info "Port range written to /var/lib/vastai_kaalia/host_port_range"

  # Configure custom apt mirror if set
  if [[ -n "${APT_MIRROR}" ]]; then
    mkdir -p /var/lib/vastai_kaalia/latest
    printf '%s' "${APT_MIRROR}" > /var/lib/vastai_kaalia/apt-select-out
    printf '%s' "${APT_MIRROR}" > /var/lib/vastai_kaalia/latest/apt-select-out
    log_info "Custom apt mirror set to: ${APT_MIRROR}"
  fi

  log_success "Network configuration done."
}

# --------------------------------------------------------------------------- #
# Step 6: Install Vast.ai Manager Software
# --------------------------------------------------------------------------- #
install_vastai() {
  log_info "=== Installing Vast.ai Manager Software ==="

  if [[ -z "${VAST_API_KEY}" ]]; then
    log_error "VAST_API_KEY is required. Get it from https://cloud.vast.ai/host/setup/"
    log_error "Usage: VAST_API_KEY=<your-key> sudo -E ./install.sh vastai"
    exit 1
  fi

  log_info "Downloading and running Vast.ai installer..."
  wget -q "https://console.vast.ai/install" -O vast_host_install.sh
  chmod +x vast_host_install.sh
  ./vast_host_install.sh "${VAST_API_KEY}"

  log_success "Vast.ai manager software installed."
  log_info "Check your machine at https://cloud.vast.ai/host/machines/"
}

# --------------------------------------------------------------------------- #
# Step 7: Install Vast.ai CLI & Test Machine
# --------------------------------------------------------------------------- #
test_machine() {
  log_info "=== Testing Machine ==="

  # Install CLI if not present
  if ! command -v vastai &>/dev/null; then
    log_info "Installing Vast.ai CLI..."
    pip3 install --upgrade vastai
  fi

  if [[ -n "${VAST_API_KEY}" ]]; then
    vastai set api-key "${VAST_API_KEY}"
  fi

  if [[ -z "${VAST_MACHINE_ID}" ]]; then
    log_error "VAST_MACHINE_ID is required for self-test."
    log_error "Find your machine ID at https://cloud.vast.ai/host/machines/"
    log_error "Usage: VAST_MACHINE_ID=<id> sudo -E ./install.sh test"
    exit 1
  fi

  log_info "Running self-test on machine ${VAST_MACHINE_ID}..."
  vastai self-test machine "${VAST_MACHINE_ID}"

  log_success "Self-test complete."
}

# --------------------------------------------------------------------------- #
# Step: All — run everything in order
# --------------------------------------------------------------------------- #
install_all() {
  install_driver
  disable_autoupdate
  setup_docker_storage
  fix_epyc_iommu
  setup_network

  if [[ -n "${VAST_API_KEY}" ]]; then
    install_vastai
  else
    log_warn "VAST_API_KEY not set — skipping Vast.ai manager install."
    log_warn "Run: VAST_API_KEY=<key> sudo -E ./install.sh vastai"
  fi

  log_success "=== Vast.ai host setup complete ==="
  log_info "Next steps:"
  log_info "  1. Reboot if prompted (driver install may require it)"
  log_info "  2. Verify GPU:  nvidia-smi -q"
  log_info "  3. Install Vast.ai manager (if skipped):  VAST_API_KEY=<key> sudo -E ./install.sh vastai"
  log_info "  4. List your machine at https://cloud.vast.ai/host/machines/"
  log_info "  5. Test: VAST_MACHINE_ID=<id> sudo -E ./install.sh test"
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
case "${MODE}" in
  all)              install_all ;;
  driver)           install_driver ;;
  docker-storage)   setup_docker_storage ;;
  disable-autoupdate) disable_autoupdate ;;
  network)          setup_network ;;
  vastai)           install_vastai ;;
  test)             test_machine ;;
  *)
    log_error "Unknown mode: '${MODE}'"
    echo "Usage: sudo $0 [all|driver|docker-storage|disable-autoupdate|network|vastai|test]"
    echo ""
    echo "  all               Run all setup steps in order"
    echo "  driver            Install NVIDIA GPU driver"
    echo "  docker-storage    Set up XFS partition for Docker"
    echo "  disable-autoupdate  Disable auto updates (prevent NVML mismatch)"
    echo "  network           Configure port range and apt mirror"
    echo "  vastai            Install Vast.ai manager software"
    echo "  test              Run self-test on your machine"
    exit 1
    ;;
esac