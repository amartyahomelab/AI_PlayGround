#!/usr/bin/env bash
set -euo pipefail

# entrypoint.sh: Simple initialization script for the Docker container

# Print hello message
echo "hello from entrypoint"

# 0) fix up PATH so ~/.local/bin (where --user installs land) is found
export PATH="$HOME/.local/bin:$PATH"
# move into the app directory
cd /home/user/app

# 1) Load secrets and export them to current shell environment
echo "🔐 Loading secrets..."
# Create a temporary file to capture environment variables from Python
TEMP_ENV_FILE=$(mktemp)

# Load secrets and export them using sec_utils.py
cd /home/user/app/envs/setup
python3 sec_utils.py "$TEMP_ENV_FILE"
cd /home/user/app

# Source the environment variables into current shell
if [ -f "$TEMP_ENV_FILE" ]; then
    source "$TEMP_ENV_FILE"
    rm "$TEMP_ENV_FILE"
    echo "✅ Environment variables exported to shell"
else
    echo "⚠️  No environment variables file created"
fi

# 2) Test API connections with the loaded environment variables
echo "🧪 Testing API connections..."
cd /home/user/app/envs/setup
python3 test_apis.py
cd /home/user/app

echo "└─ CLI finished; dropping you into a shell ───────"

# 3) drop into interactive bash with all environment variables available
exec /bin/bash -i