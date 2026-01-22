#!/bin/bash

echo "[entrypoint] Using UID=$UID GID=$GID USERNAME=$USERNAME"

# Detect GPU vendor for runtime config
echo "[entrypoint] Detecting GPU vendor..."
GPU_VENDOR="${GPU_VENDOR:-auto}"

if [ "$GPU_VENDOR" = "auto" ]; then
  GPU_DESC="$(lspci | grep -i 'VGA\|3D\|Display')"

  if echo "$GPU_DESC" | grep -qi nvidia; then
    GPU_VENDOR="nvidia"
  elif echo "$GPU_DESC" | grep -qi amd; then
    GPU_VENDOR="amd"
  elif echo "$GPU_DESC" | grep -qi intel; then
    GPU_VENDOR="intel"
  else
    GPU_VENDOR="none"
  fi
fi

echo "[entrypoint] Detected GPU vendor: $GPU_VENDOR"

# Vendor-specific runtime environment setup
case "$GPU_VENDOR" in
  nvidia)
    export NVIDIA_VISIBLE_DEVICES=all
    export NVIDIA_DRIVER_CAPABILITIES=all
    echo "[entrypoint] NVIDIA runtime variables configured."
    ;;
  amd)
    export ROC_ENABLE_PRE_VEGA=1
    echo "[entrypoint] ROCm runtime variable configured."
    ;;
  *)
    echo "[entrypoint] No supported GPU vendor detected or required."
    ;;
esac

# Note: Video group membership is handled by docker-compose group_add
# for AMD/Intel. NVIDIA uses nvidia-container-toolkit which doesn't need it.

# Execute the command passed to the container, or start an interactive shell
if [ $# -gt 0 ]; then
  exec "$@"
else
  exec bash
fi
