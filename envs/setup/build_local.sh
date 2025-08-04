#!/bin/bash


# Simplified build and run script for agent-dev container
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_ROOT"

VOLUME_NAME="ai-dev-bash-history"
IMAGE_NAME="ai-dev"
CONTAINER_NAME="ai-dev-container"
DOCKERFILE_PATH="envs/test/agent-dev/Dockerfile"

# Ensure Docker volume exists
docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1 || docker volume create "$VOLUME_NAME"

# Build image
docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" .

# Prepare mounts

# Prepare mounts (named volume must not use realpath or $PWD)
MOUNTS=(
  -v "$(pwd)":/home/user/app/
)




# Run container
docker run -it --rm --name "$CONTAINER_NAME" \
  --network langgraph-network \
  "${MOUNTS[@]}" \
  --env-file "$PWD/envs/test/.env" \
  -e SKIP_HEALTH_CHECK=true \
  --entrypoint bash \
  "$IMAGE_NAME" -c "chmod +x /home/user/app/envs/test/agent-dev/entrypoint.sh && exec /home/user/app/envs/test/agent-dev/entrypoint.sh"