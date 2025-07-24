#!/bin/bash
set -euo pipefail

# PostgreSQL Container Entrypoint with Secret Management
# 🎯 PURPOSE: Initialize PostgreSQL with secret management integration
# - Load database passwords from secret management system
# - Set up multiple databases (postgres, langsmith)
# - Call original PostgreSQL entrypoint

echo "�️ PostgreSQL Container Starting..."

# 1) Load secrets if available
if [ -f "/run/secrets.yaml" ] && [ -f "/opt/sec_utils.py" ]; then
    echo "🔐 Loading database secrets..."
    
    # Create temporary file for environment variables
    TEMP_ENV_FILE=$(mktemp)
    
    # Load secrets using Python script
    cd /opt
    python3 sec_utils.py "$TEMP_ENV_FILE" 2>/dev/null || echo "⚠️ Secret loading failed, using defaults"
    
    # Source environment variables if successful
    if [ -f "$TEMP_ENV_FILE" ] && [ -s "$TEMP_ENV_FILE" ]; then
        source "$TEMP_ENV_FILE"
        rm "$TEMP_ENV_FILE"
        echo "✅ Database secrets loaded"
        
        # Override default password if loaded from secrets
        if [ -n "${POSTGRES_PASSWORD:-}" ]; then
            export POSTGRES_PASSWORD
            echo "🔐 Using password from secret management"
        fi
    else
        echo "⚠️ Using default database password"
        [ -f "$TEMP_ENV_FILE" ] && rm -f "$TEMP_ENV_FILE"
    fi
else
    echo "⚠️ Secret management not available, using default credentials"
fi

# 2) Set up default environment variables if not provided
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
export POSTGRES_DB="${POSTGRES_DB:-postgres}"

echo "📊 Database configuration:"
echo "   User: $POSTGRES_USER"
echo "   Default DB: $POSTGRES_DB"
echo "   Extensions: pgvector, pg_stat_statements"

# 3) Call the original PostgreSQL entrypoint
echo "🚀 Starting PostgreSQL server..."
exec docker-entrypoint.sh "$@"
