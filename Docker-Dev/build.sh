#!/bin/bash

set -e  # Exit immediately if a command fails

echo "[build-engine.sh] Starting O3DE engine build..."

# Set required environment variables for env_linux.sh
export CONFIGURATION="profile"
export CMAKE_TARGET="Editor;GameLauncher"
export O3DE_ROOT="${O3DE_ROOT:-$(pwd)}"
export OUTPUT_DIRECTORY="$O3DE_ROOT/build"

# Print environment setup
echo "[build-engine.sh] O3DE root: $O3DE_ROOT"
echo "[build-engine.sh] Build directory: $OUTPUT_DIRECTORY"
echo "[build-engine.sh] Configuration: $CONFIGURATION"
echo "[build-engine.sh] Target: $CMAKE_TARGET"

# Bootstrap python
echo "[build-engine.sh] Bootstrapping Python..."
${O3DE_ROOT}/python/get_python.sh

# Run official build script from O3DE root so SOURCE_DIRECTORY is correct
(
  cd "$O3DE_ROOT"
  "$O3DE_ROOT/scripts/build/Platform/Linux/build_linux.sh"
)

echo "[build-engine.sh] Build complete."
