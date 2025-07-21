#!/usr/bin/env bash
set -euo pipefail

# entrypoint.sh: Initialization script for the Docker container

# Print hello message
echo "hello from entrypoint"

# 0) fix up PATH so ~/.local/bin (where --user installs land) is found
export PATH="$HOME/.local/bin:$PATH"

# move into the app directory
cd /home/user/app

# 1) Load secrets and set up environment variables
echo "Setting up environment..."
TEMP_ENV_FILE="/tmp/env_vars.sh"
if python3 /home/user/app/envs/setup/export_env.py > "$TEMP_ENV_FILE"; then
    # Source the generated environment variables
    if [[ -f "$TEMP_ENV_FILE" && -s "$TEMP_ENV_FILE" ]]; then
        source "$TEMP_ENV_FILE"
        rm -f "$TEMP_ENV_FILE"
        echo "Environment setup completed"
    else
        echo "No environment variables to set"
    fi
else
    echo "Environment setup had issues, continuing anyway"
    [[ -f "$TEMP_ENV_FILE" ]] && rm -f "$TEMP_ENV_FILE"
fi

# 2) Test API connections
echo "Testing API connections..."
if python3 -c "
import sys
sys.path.insert(0, '/home/user/app/envs/setup')
from api_utils import test_all_apis
test_all_apis()
"; then
    echo "API connection tests completed"
else
    echo "Some API tests failed, but continuing"
fi

echo "└─ CLI finished; dropping you into a shell ───────"

# 3) drop into interactive bash
exec /bin/bash -i