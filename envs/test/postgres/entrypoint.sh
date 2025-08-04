#!/bin/bash
set -euo pipefail

# PostgreSQL Container Entrypoint with Secret Management
# 🎯 PURPOSE: Initialize PostgreSQL with secret management integration
# - Load database passwords from secret management system
# - Set up multiple databases (postgres, langsmith)
# - Call original PostgreSQL entrypoint

echo "🐘 PostgreSQL Container Starting..."


echo "📊 Database configuration:"
echo "   User: $POSTGRES_USER"
echo "   Default DB: $POSTGRES_DB"
echo "   Extensions: pgvector, pg_stat_statements"

# Call the original PostgreSQL entrypoint
echo "🚀 Starting PostgreSQL server..."
exec docker-entrypoint.sh "$@"
