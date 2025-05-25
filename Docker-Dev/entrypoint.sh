#!/bin/bash

# Map UID/GID from environment or fallback
: "${UID:=1000}"
: "${GID:=1000}"
: "${USERNAME:=devuser}"

export UID GID USERNAME

echo "[entrypoint] Using UID=$UID GID=$GID USERNAME=$USERNAME"

# Commented out XDG setup for headless build-only usage
# mkdir -p /run/user/$UID
# chmod 7700 /run/user/$UID
# export XDG_RUNTIME_DIR=/run/user/$UID
# echo "[entrypoint] Set XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

# Start an interactive shell directly
exec bash