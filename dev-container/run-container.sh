#!/bin/bash
set -e

# Run the o3de-dev container with auto-detected or specified GPU profile
# Usage: ./run-container.sh [--profile nvidia|amd|intel]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse command line arguments
GPU_PROFILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile|-p)
            GPU_PROFILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--profile nvidia|amd|intel]"
            echo ""
            echo "Options:"
            echo "  --profile, -p    Specify GPU vendor (nvidia, amd, intel)"
            echo "                   If not specified, auto-detects from lspci"
            echo ""
            echo "Examples:"
            echo "  $0               # Auto-detect GPU"
            echo "  $0 --profile amd # Force AMD profile"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Auto-detect GPU if not specified
if [ -z "$GPU_PROFILE" ]; then
    echo "[run-container.sh] Auto-detecting GPU vendor..."
    GPU_DESC="$(lspci 2>/dev/null | grep -i 'VGA\|3D\|Display' || true)"

    if echo "$GPU_DESC" | grep -qi nvidia; then
        GPU_PROFILE="nvidia"
    elif echo "$GPU_DESC" | grep -qi amd; then
        GPU_PROFILE="amd"
    elif echo "$GPU_DESC" | grep -qi intel; then
        GPU_PROFILE="intel"
    else
        echo "[run-container.sh] WARNING: Could not detect GPU vendor from lspci output:"
        echo "$GPU_DESC"
        echo ""
        echo "Please specify manually with --profile nvidia|amd|intel"
        exit 1
    fi
    echo "[run-container.sh] Detected GPU: $GPU_PROFILE"
fi

# Map profile to service name
case "$GPU_PROFILE" in
    nvidia)
        SERVICE_NAME="o3de-dev"
        ;;
    amd)
        SERVICE_NAME="o3de-dev-amd"
        ;;
    intel)
        SERVICE_NAME="o3de-dev-intel"
        ;;
    *)
        echo "[run-container.sh] ERROR: Unknown GPU profile: $GPU_PROFILE"
        echo "Valid profiles: nvidia, amd, intel"
        exit 1
        ;;
esac

echo "[run-container.sh] Using profile: $GPU_PROFILE, service: $SERVICE_NAME"

# Grant X access to local containers
echo "[run-container.sh] Granting X11 access..."
xhost +local:docker 2>/dev/null || echo "[run-container.sh] WARNING: xhost command failed (X11 forwarding may not work)"

# Run the container (use env to bypass bash's readonly UID variable)
echo "[run-container.sh] Launching container..."
env UID="$(id -u)" GID="$(id -g)" docker compose --profile "$GPU_PROFILE" run --rm "$SERVICE_NAME"

# Revoke X access afterwards
xhost -local:docker 2>/dev/null || true

echo "[run-container.sh] Container exited."
