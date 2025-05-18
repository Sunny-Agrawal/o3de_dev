#!/bin/bash

# Map UID/GID from environment
: "${UID:=1000}"
: "${GID:=1000}"
: "${USERNAME:=devuser}"

# Create runtime directory for GUI apps (Qt, etc.)
mkdir -p /run/user/$UID
chown $USERNAME:$USERNAME /run/user/$UID
chmod 7700 /run/user/$UID
export XDG_RUNTIME_DIR=/run/user/$UID

# Launch shell as the non-root dev user
exec su - $USERNAME
