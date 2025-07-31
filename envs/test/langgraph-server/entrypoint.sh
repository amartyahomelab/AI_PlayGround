#!/bin/bash

set -e

echo "⚡ Starting LangGraph Server with Studio UI..."

# Decode base64 environment variables first
echo "🔓 Decoding base64 environment variables..."
if [ -f "/opt/decode_env.sh" ]; then
    # Use the shell script to decode and generate export statements
    /opt/decode_env.sh export
    
    # Source the generated environment script to make variables available to shell
    if [ -f "/tmp/decoded_env.sh" ]; then
        source /tmp/decoded_env.sh
    else
        echo "❌ Failed to generate decoded environment variables"
        exit 1
    fi
else
    echo "⚠️ Warning: decode_env.sh not found, skipping base64 decoding"
fi

# Validate API connections immediately after decoding
echo "🔍 Validating API connections..."
if [ -f "/opt/api_utils.py" ]; then
    export PYTHONPATH="/opt:$PYTHONPATH"
    python3 -c "
import sys
sys.path.insert(0, '/opt')
try:
    from api_utils import test_all_apis
    test_all_apis()
    print('✅ API validation completed')
except Exception as e:
    print(f'⚠️ API validation failed: {e}')
    print('🚀 Continuing with server startup anyway...')
"
else
    echo "⚠️ Warning: api_utils.py not found, skipping API validation"
fi

# Configuration
export HOST=${HOST:-0.0.0.0}
export PORT=${PORT:-2024}

# Build DATABASE_URI for the official LangGraph container
export DATABASE_URI="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"

# Wait for dependencies
echo "⏳ Waiting for dependencies..."

# Wait for PostgreSQL
echo "  → Waiting for PostgreSQL..."
timeout=60
while ! nc -z $POSTGRES_HOST $POSTGRES_PORT; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "❌ Timeout waiting for PostgreSQL"
        exit 1
    fi
done
echo "✅ PostgreSQL is ready"

# Wait for Qdrant
echo "  → Waiting for Qdrant..."
timeout=60
while ! nc -z qdrant 6333; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "❌ Timeout waiting for Qdrant"
        exit 1
    fi
done
echo "✅ Qdrant is ready"

# Display configuration
echo "🔧 LangGraph Server Configuration:"
echo "   Host: $HOST"
echo "   Port: $PORT"
echo "   Database URI: $DATABASE_URI"
echo "   Vector Store: $QDRANT_URL"
echo "   API Keys: ${OPENAI_API_KEY:+OPENAI***} ${LANGSMITH_API_KEY:+LANGSMITH***}"

# Start LangGraph development server
echo "🚀 Starting LangGraph development server with Studio UI..."
echo "   API: http://localhost:$PORT"
echo "   Studio: http://localhost:$PORT (bundled)"

# Change to the graphs directory where langgraph.json is located
cd /app/graphs

# Use the official langgraph dev command to start both API and Studio
exec langgraph dev --host "$HOST" --port "$PORT"
