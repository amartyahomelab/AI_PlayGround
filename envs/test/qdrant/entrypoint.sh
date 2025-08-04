#!/bin/bash
set -euo pipefail

# Qdrant Vector Database Entrypoint
# 🎯 PURPOSE: Initialize Qdrant vector database
# - Simple startup with health monitoring
# - No complex secret management needed

echo "🔍 Qdrant Vector Database Starting..."


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
