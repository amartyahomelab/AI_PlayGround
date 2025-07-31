#!/bin/bash

# Temporarily disable exit on error for debugging
set +e

echo "🔓 Simple base64 decoder for testing..."

# List of environment variables that need base64 decoding
BASE64_ENV_VARS=(
    "LANGSMITH_API_KEY"
    "GITHUB_TOKEN"
    "OPENAI_API_KEY"
    "GOOGLE_API_KEY"
    "ANTHROPIC_API_KEY"
)

# Smart base64 decode function - detects if value is already decoded
decode_simple() {
    local encoded="$1"
    if [ -n "$encoded" ]; then
        # Check if value is already decoded by looking for common API key patterns
        if echo "$encoded" | grep -qE "^(sk-|lsv2_|ghp_|xai-|dckr_pat_)"; then
            # Already decoded, return as-is
            echo "$encoded"
        else
            # Try to decode, fall back to original if it fails
            echo "$encoded" | base64 -d 2>/dev/null || echo "$encoded"
        fi
    fi
}

# Generate export script
if [ "$1" = "export" ]; then
    echo "#!/bin/bash" > /tmp/decoded_env.sh
    decoded_count=0
    
    echo "🔍 Processing environment variables..."
    for var_name in "${BASE64_ENV_VARS[@]}"; do
        encoded_value="${!var_name}"
        echo "  Checking $var_name: ${encoded_value:0:20}..." # Show first 20 chars
        if [ -n "$encoded_value" ]; then
            decoded_value=$(decode_simple "$encoded_value")
            if [ "$decoded_value" != "$encoded_value" ]; then
                echo "export ${var_name}='${decoded_value}'" >> /tmp/decoded_env.sh
                ((decoded_count++))
                echo "    ✅ Decoded $var_name"
            else
                echo "    ⏭️ Skipped $var_name (no change needed)"
            fi
        else
            echo "    ⚠️ Empty: $var_name"
        fi
    done
    
    echo "echo 'Exported $decoded_count variables'" >> /tmp/decoded_env.sh
    chmod +x /tmp/decoded_env.sh
    echo "Generated export script with $decoded_count variables"
else
    echo "Simple decode mode - use 'export' for container usage"
fi
