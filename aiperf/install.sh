#!/usr/bin/env bash
# Install AIPerf (https://github.com/ai-dynamo/aiperf) into a Python venv.
# Reuses an existing venv and skips reinstall if aiperf is already available.
set -euo pipefail

VENV_DIR="${VENV_DIR:-$HOME/venv/aiperf}"

# Create venv only if it doesn't exist or is incomplete
if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    echo "Creating virtual environment at $VENV_DIR ..."
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

# Activate the venv
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# Install aiperf only if not already installed
if ! command -v aiperf &>/dev/null; then
    echo "Installing aiperf ..."
    pip install aiperf
else
    echo "aiperf is already installed, skipping."
fi

echo "Done. Activate with:  source $VENV_DIR/bin/activate"