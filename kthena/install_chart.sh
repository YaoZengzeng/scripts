#!/bin/bash

# Install Kthena via Helm, based on the latest chart schema:
#   https://github.com/volcano-sh/kthena/tree/main/charts/kthena
#
# Component enablement uses the new subchart layout:
#   - Router     -> networking.enabled + networking.kthenaRouter.enabled
#   - Controller -> workload.enabled
#
# Session Boost (session-aware boosting to maximize prefix cache hits for
# multi-turn conversations) can be toggled and tuned via the flags below. It maps
# to networking.kthenaRouter.sessionBoost.* in the chart values.

set -euo pipefail

CHART_PATH="/root/kthena/charts/kthena"
NAMESPACE="kthena-system"
RELEASE="test-release"

INSTALL_ROUTER=true
INSTALL_CONTROLLER=true
COMPONENT_SPECIFIED=false

# Session Boost configuration (disabled by default, matching chart defaults).
SESSION_BOOST_ENABLED=false
SESSION_BOOST_HEADER="X-Session-ID"
SESSION_BOOST_MAX_SESSIONS=4096
SESSION_BOOST_INFLIGHT_PER_POD=16
SESSION_BOOST_GRACE_PERIOD="0s"
SESSION_BOOST_TIMEOUT="30s"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -r, --router-only       Install router only"
    echo "  -c, --controller-only   Install controller manager only"
    echo ""
    echo "Session Boost (maps to networking.kthenaRouter.sessionBoost.*):"
    echo "  -s, --session-boost                       Enable session boost (default: disabled)"
    echo "      --session-boost-header VALUE          HTTP header used to identify sessions (default: ${SESSION_BOOST_HEADER})"
    echo "      --session-boost-max-sessions VALUE    Max warm sessions in the LRU cache (default: ${SESSION_BOOST_MAX_SESSIONS})"
    echo "      --session-boost-inflight-per-pod VALUE  Max inflight requests per backend pod (default: ${SESSION_BOOST_INFLIGHT_PER_POD})"
    echo "      --session-boost-grace-period VALUE    Wait time for a same-session follow-up (default: ${SESSION_BOOST_GRACE_PERIOD})"
    echo "      --session-boost-timeout VALUE         Max queue wait before HTTP 504 (default: ${SESSION_BOOST_TIMEOUT})"
    echo ""
    echo "  -h, --help              Display this help message"
    echo ""
    echo "By default, both router and controller manager are installed and session boost is disabled."
    exit 0
}

require_value() {
    # $1 = flag name, $2 = value (may be empty/missing)
    if [ -z "${2:-}" ]; then
        echo "Error: $1 requires a value"
        exit 1
    fi
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
        -s|--session-boost)
            SESSION_BOOST_ENABLED=true
            shift
            ;;
        --session-boost-header)
            require_value "$1" "${2:-}"
            SESSION_BOOST_HEADER="$2"
            shift 2
            ;;
        --session-boost-max-sessions)
            require_value "$1" "${2:-}"
            SESSION_BOOST_MAX_SESSIONS="$2"
            shift 2
            ;;
        --session-boost-inflight-per-pod)
            require_value "$1" "${2:-}"
            SESSION_BOOST_INFLIGHT_PER_POD="$2"
            shift 2
            ;;
        --session-boost-grace-period)
            require_value "$1" "${2:-}"
            SESSION_BOOST_GRACE_PERIOD="$2"
            shift 2
            ;;
        --session-boost-timeout)
            require_value "$1" "${2:-}"
            SESSION_BOOST_TIMEOUT="$2"
            shift 2
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

# Session boost only makes sense when the router is installed.
if [ "$SESSION_BOOST_ENABLED" = true ] && [ "$INSTALL_ROUTER" != true ]; then
    echo "Error: --session-boost requires the router to be installed (do not combine with --controller-only)"
    exit 1
fi

# Assemble Helm --set flags.
HELM_ARGS=(
    --set "networking.enabled=${INSTALL_ROUTER}"
    --set "networking.kthenaRouter.enabled=${INSTALL_ROUTER}"
    --set "workload.enabled=${INSTALL_CONTROLLER}"
    --set "networking.kthenaRouter.sessionBoost.enabled=${SESSION_BOOST_ENABLED}"
)

if [ "$SESSION_BOOST_ENABLED" = true ]; then
    HELM_ARGS+=(
        --set "networking.kthenaRouter.sessionBoost.header=${SESSION_BOOST_HEADER}"
        --set "networking.kthenaRouter.sessionBoost.maxSessions=${SESSION_BOOST_MAX_SESSIONS}"
        --set "networking.kthenaRouter.sessionBoost.inflightPerPod=${SESSION_BOOST_INFLIGHT_PER_POD}"
        --set "networking.kthenaRouter.sessionBoost.gracePeriod=${SESSION_BOOST_GRACE_PERIOD}"
        --set "networking.kthenaRouter.sessionBoost.timeout=${SESSION_BOOST_TIMEOUT}"
    )
fi

echo "Installing Kthena:"
echo "  router:        ${INSTALL_ROUTER}"
echo "  controller:    ${INSTALL_CONTROLLER}"
echo "  session boost: ${SESSION_BOOST_ENABLED}"

helm install "${RELEASE}" "${CHART_PATH}" --namespace "${NAMESPACE}" --create-namespace \
    "${HELM_ARGS[@]}"
