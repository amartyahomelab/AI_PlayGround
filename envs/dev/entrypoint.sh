#!/usr/bin/env bash
set -euo pipefail

# entrypoint.sh: Simple initialization script for the Docker container

# Print hello message
echo "hello from entrypoint"

# 0) fix up PATH so ~/.local/bin (where --user installs land) is found
export PATH="$HOME/.local/bin:$PATH"
# move into the app directory
cd /home/user/app



echo "└─ CLI finished; dropping you into a shell ───────"

# 6) drop into interactive bash
exec /bin/bash -i