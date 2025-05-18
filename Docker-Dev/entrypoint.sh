#!/bin/bash

# Map UID/GID from environment or fallback
: "${UID:=1000}"
: "${GID:=1000}"
: "${USERNAME:=devuser}"

export UID GID USERNAME

echo "[entrypoint] Using UID=$UID GID=$GID USERNAME=$USERNAME"

# Setup runtime dir for GUI apps (XDG)
mkdir -p /run/user/$UID
chown $USERNAME:$USERNAME /run/user/$UID
chmod 7700 /run/user/$UID
export XDG_RUNTIME_DIR=/run/user/$UID
echo "[entrypoint] Set XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

# Launch shell as the non-root dev user
exec su - $USERNAME
