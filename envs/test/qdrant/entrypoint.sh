#!/bin/bash
set -euo pipefail

# Qdrant Vector Database Entrypoint
# 🎯 PURPOSE: Initialize Qdrant vector database
# - Simple startup with health monitoring
# - No complex secret management needed

echo "🔍 Qdrant Vector Database Starting..."

# Decode base64 environment variables first
echo "🔓 Decoding base64 environment variables..."
if [ -f "/opt/decode_env.sh" ]; then
    # Use the shell script to decode and generate export statements
    /opt/decode_env.sh export
    
    # Source the generated environment script to make variables available to shell
    if [ -f "/tmp/decoded_env.sh" ]; then
        source /tmp/decoded_env.sh
        echo "✅ Base64 environment variables decoded and exported"
    else
        echo "❌ Failed to generate decoded environment variables"
        exit 1
    fi
else
    echo "⚠️ Warning: decode_env.sh not found, skipping base64 decoding"
fi

# Skip API validation for qdrant - not needed for vector database service
echo "ℹ️ Skipping API validation for Qdrant service"

# Configure Qdrant settings
export QDRANT__SERVICE__HTTP_PORT="${QDRANT__SERVICE__HTTP_PORT:-6333}"
export QDRANT__SERVICE__GRPC_PORT="${QDRANT__SERVICE__GRPC_PORT:-6334}"

# Ensure storage directory exists and has correct permissions
mkdir -p /qdrant/storage

echo "📊 Qdrant configuration:"
echo "   HTTP Port: $QDRANT__SERVICE__HTTP_PORT"
echo "   gRPC Port: $QDRANT__SERVICE__GRPC_PORT"
echo "   Storage: /qdrant/storage"

# Start Qdrant
echo "🚀 Starting Qdrant vector database..."
exec ./qdrant
