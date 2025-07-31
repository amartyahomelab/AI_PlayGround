#!/bin/bash
set -euo pipefail

# PostgreSQL Container Entrypoint with Secret Management
# 🎯 PURPOSE: Initialize PostgreSQL with secret management integration
# - Load database passwords from secret management system
# - Set up multiple databases (postgres, langsmith)
# - Call original PostgreSQL entrypoint

echo "🐘 PostgreSQL Container Starting..."

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

# Skip API validation for postgres - not needed for database service
echo "ℹ️ Skipping API validation for PostgreSQL service"

echo "📊 Database configuration:"
echo "   User: $POSTGRES_USER"
echo "   Default DB: $POSTGRES_DB"
echo "   Extensions: pgvector, pg_stat_statements"

# Call the original PostgreSQL entrypoint
echo "🚀 Starting PostgreSQL server..."
exec docker-entrypoint.sh "$@"
