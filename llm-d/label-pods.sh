#!/bin/bash
# -*- indent-tabs-mode: nil; tab-width: 2; sh-indentation: 2; -*-
#
# Add "modelserving.volcano.sh/name: vllm-qwen-06b" label to llm-d decode pods.
#
# This script patches the decode Deployment's pod template so that the label
# persists across pod restarts and rollouts. Can be re-run safely at any time.
#
# Usage:
#   ./label-pods.sh [namespace]
#
# Environment variables:
#   NAMESPACE  (default: llm-d)

set -e
set -o pipefail

NAMESPACE=${1:-${NAMESPACE:-"llm-d"}}
LABEL_KEY="modelserving.volcano.sh/name"
LABEL_VALUE="vllm-qwen-06b"

COLOR_RESET=$'\e[0m'
COLOR_GREEN=$'\e[32m'
COLOR_RED=$'\e[31m'

log_success() { echo "${COLOR_GREEN}✅ $*${COLOR_RESET}"; }
log_error()   { echo "${COLOR_RED}❌ $*${COLOR_RESET}" >&2; }
log_info()    { echo "ℹ️  $*"; }

log_info "Patching decode deployment in namespace '${NAMESPACE}' to add label '${LABEL_KEY}: ${LABEL_VALUE}'..."

decode_deploy=$(kubectl get deploy -n "${NAMESPACE}" -l llm-d.ai/role=decode -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [[ -n "${decode_deploy}" ]]; then
  kubectl patch deployment "${decode_deploy}" -n "${NAMESPACE}" \
    --type=json \
    -p="[{\"op\":\"add\",\"path\":\"/spec/template/metadata/labels/${LABEL_KEY/\//~1}\",\"value\":\"${LABEL_VALUE}\"}]"
  log_success "Label '${LABEL_KEY}: ${LABEL_VALUE}' added to deployment '${decode_deploy}' pod template."
  log_info "Pods will be recreated with the new label via rolling update."
else
  log_info "No decode deployment found. Labeling existing pods directly..."
  kubectl label pods -n "${NAMESPACE}" -l llm-d.ai/role=decode \
    "${LABEL_KEY}=${LABEL_VALUE}" --overwrite
  log_success "Label applied to existing pods (note: new pods won't inherit this label)."
fi
