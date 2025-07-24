#!/bin/bash

set -e

echo "⚡ Starting LangGraph Server with Studio UI..."

# Load secrets if available
if [ -f "/run/secrets.yaml" ]; then
    echo "📁 Loading secrets from secret management system..."
    
    # Use the proper sec_utils.py load_secrets() function
    if [ -f "/opt/sec_utils.py" ]; then
        # Add Python path and run load_secrets function
        export PYTHONPATH="/opt:$PYTHONPATH"
        
        # Test if the function works first
        if python3 -c "
import sys
sys.path.insert(0, '/opt')
from sec_utils import load_secrets
load_secrets()
" 2>/dev/null; then
            echo "✅ Successfully loaded secrets using sec_utils.py"
        else
            echo "⚠️ Warning: sec_utils.py failed, falling back to manual parsing"
            # Manual fallback parsing
            LANGSMITH_B64=$(grep "LANGSMITH_API_KEY:" /run/secrets.yaml | cut -d' ' -f2)
            if [ ! -z "$LANGSMITH_B64" ]; then
                export LANGSMITH_API_KEY=$(echo "$LANGSMITH_B64" | base64 -d)
                echo "✅ Successfully decoded LANGSMITH_API_KEY (manual)"
            fi
            
            OPENAI_B64=$(grep "OPENAI_API_KEY:" /run/secrets.yaml | cut -d' ' -f2)
            if [ ! -z "$OPENAI_B64" ]; then
                export OPENAI_API_KEY=$(echo "$OPENAI_B64" | base64 -d)
                echo "✅ Successfully decoded OPENAI_API_KEY (manual)"
            fi
        fi
    else
        echo "⚠️ Warning: sec_utils.py not found, using manual parsing"
        # Manual fallback parsing
        LANGSMITH_B64=$(grep "LANGSMITH_API_KEY:" /run/secrets.yaml | cut -d' ' -f2)
        if [ ! -z "$LANGSMITH_B64" ]; then
            export LANGSMITH_API_KEY=$(echo "$LANGSMITH_B64" | base64 -d)
            echo "✅ Successfully decoded LANGSMITH_API_KEY (manual)"
        fi
        
        OPENAI_B64=$(grep "OPENAI_API_KEY:" /run/secrets.yaml | cut -d' ' -f2)
        if [ ! -z "$OPENAI_B64" ]; then
            export OPENAI_API_KEY=$(echo "$OPENAI_B64" | base64 -d)
            echo "✅ Successfully decoded OPENAI_API_KEY (manual)"
        fi
    fi
else
    echo "📝 Secret management not available, using environment variables"
fi

# Configuration
export HOST=${HOST:-0.0.0.0}
export PORT=${PORT:-2024}
export POSTGRES_HOST=${POSTGRES_HOST:-postgres}
export POSTGRES_PORT=${POSTGRES_PORT:-5432}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-postgres}
export QDRANT_URL=${QDRANT_URL:-http://qdrant:6333}

# Use PostgreSQL password from secrets or environment
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD=${POSTGRES_PASSWORD_FALLBACK:-postgres}
fi

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
echo "   API Keys: ${OPENAI_API_KEY:+***configured***}"

# Start LangGraph development server
echo "🚀 Starting LangGraph development server with Studio UI..."
echo "   API: http://localhost:$PORT"
echo "   Studio: http://localhost:$PORT (bundled)"

# Change to the graphs directory where langgraph.json is located
cd /app/graphs

# Use the official langgraph dev command to start both API and Studio
exec langgraph dev --host "$HOST" --port "$PORT"
