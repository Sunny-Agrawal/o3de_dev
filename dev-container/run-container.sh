#!/bin/bash

# Run the o3de-dev container using docker compose
# Requires UID and GID to be set in .env file in the same directory

echo "[run-container.sh] Launching o3de-dev container..."

# Grant X access to local containers
xhost +local:docker

# Run the container
docker compose run --rm o3de-dev

# Revoke X access afterwards
xhost -local:docker
