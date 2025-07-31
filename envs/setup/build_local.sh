#!/bin/bash

# Script to check/create Docker volume, build image, and run container

# Detect if we're running from the root or project directory and adjust accordingly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The script is in envs/setup, so we need to go up two levels to reach the project root
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Change to project root directory
cd "$PROJECT_ROOT"

# Variables
VOLUME_NAME="ai-dev-bash-history"
IMAGE_NAME="ai-dev"
CONTAINER_NAME="ai-dev-container"
DOCKERFILE_PATH="envs/dev/Dockerfile"

# Check if the Docker volume exists
if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    echo "Volume $VOLUME_NAME exists."
else
    echo "Volume $VOLUME_NAME does not exist. Creating it..."
    docker volume create "$VOLUME_NAME"
    if [ $? -eq 0 ]; then
        echo "Volume $VOLUME_NAME created successfully."
    else
        echo "Failed to create volume $VOLUME_NAME."
        exit 1
    fi
fi

# Build the Docker image
echo "Building Docker image $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" .
if [ $? -eq 0 ]; then
    echo "Docker image $IMAGE_NAME built successfully."
else
    echo "Failed to build Docker image $IMAGE_NAME."
    exit 1
fi

# Note: decrypt_secrets.sh and update_secrets.sh scripts not available in envs structure
# If needed, these should be created or the references removed

# Run the Docker container
echo "Running Docker container $CONTAINER_NAME..."
docker run -it --rm --name "$CONTAINER_NAME" \
  -v "$VOLUME_NAME:/home/user/" \
  -v "$PWD/envs/config/secrets.yaml":/run/secrets.yaml:ro \
  -v "$(pwd):/home/user/app/" \
  --entrypoint bash \
  "$IMAGE_NAME" -c "chmod +x /home/user/app/envs/dev/entrypoint.sh && \
  exec /home/user/app/envs/dev/entrypoint.sh"
if [ $? -eq 0 ]; then
    echo "Docker container $CONTAINER_NAME ran successfully."
else
    echo "Failed to run Docker container $CONTAINER_NAME."
    exit 1
fi