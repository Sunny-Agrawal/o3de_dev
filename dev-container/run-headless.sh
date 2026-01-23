#!/bin/bash
set -e

# Run container in headless mode (no X11/display required)
# Perfect for SSH, CI/CD, or automated builds
#
# Usage: ./run-headless.sh [command...]
#
# Examples:
#   ./run-headless.sh                                    # Interactive shell
#   ./run-headless.sh ./dev-container/build-all.sh       # Build engine
#   ./run-headless.sh ./dev-container/build-all.sh --project AutomatedTesting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Auto-detect GPU
echo "[run-headless.sh] Auto-detecting GPU vendor..."
GPU_DESC="$(lspci 2>/dev/null | grep -i 'VGA\|3D\|Display' || true)"

if echo "$GPU_DESC" | grep -qi nvidia; then
    GPU_PROFILE="nvidia"
elif echo "$GPU_DESC" | grep -qi amd; then
    GPU_PROFILE="amd"
elif echo "$GPU_DESC" | grep -qi intel; then
    GPU_PROFILE="intel"
else
    echo "[run-headless.sh] WARNING: Could not detect GPU, defaulting to nvidia profile"
    GPU_PROFILE="nvidia"
fi

echo "[run-headless.sh] Detected GPU: $GPU_PROFILE"

# Map profile to service name
case "$GPU_PROFILE" in
    nvidia) SERVICE_NAME="o3de-dev" ;;
    amd)    SERVICE_NAME="o3de-dev-amd" ;;
    intel)  SERVICE_NAME="o3de-dev-intel" ;;
esac

echo "[run-headless.sh] Running headless (no X11)..."

# Run container without X11 (no xhost, no DISPLAY)
if [ $# -gt 0 ]; then
    # Run with provided command
    echo "[run-headless.sh] Executing: $@"
    env UID="$(id -u)" GID="$(id -g)" DISPLAY="" \
        docker compose --profile "$GPU_PROFILE" run --rm "$SERVICE_NAME" "$@"
else
    # Interactive shell
    echo "[run-headless.sh] Starting interactive shell..."
    env UID="$(id -u)" GID="$(id -g)" DISPLAY="" \
        docker compose --profile "$GPU_PROFILE" run --rm "$SERVICE_NAME"
fi

echo "[run-headless.sh] Container exited."
