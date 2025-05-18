#!/bin/bash

# Run the o3de-dev container using docker compose
# Requires UID and GID to be set in .env file in the same directory

echo "[run-container.sh] Launching o3de-dev container..."
docker compose run --rm o3de-dev
