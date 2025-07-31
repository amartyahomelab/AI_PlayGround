#!/usr/bin/env bash
set -euo pipefail

# Agent Dev Container Entrypoint
# 🎯 PURPOSE: Initialize development environment with secret management
# - Load secrets from mounted /run/secrets.yaml 
# - Export environment variables for LLM APIs
# - Test API connections 
# - Connect to LangGraph services network
# - Drop into interactive shell for development

echo "🚀 Agent Development Container Starting..."

# 0) Fix up PATH so ~/.local/bin (where --user installs land) is found
export PATH="$HOME/.local/bin:$PATH"

# Move into the app directory
cd /home/user/app

# 1) Load secrets and export them to current shell environment
echo "🔐 Loading secrets..."

# Check if we have the secret management script
if [ -f "/run/secrets.yaml" ] && [ -f "/opt/sec_utils.py" ]; then
    # Create a temporary file to capture environment variables from Python
    TEMP_ENV_FILE=$(mktemp)
    
    # Load secrets and export them using sec_utils.py
    echo "📁 Using mounted secret management system..."
    cd /opt
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
else
    echo "⚠️  Secret management files not found - running without API keys"
    echo "💡 Mount secrets.yaml to /run/secrets.yaml for full functionality"
fi

# 2) Test connections to LangGraph services if available
echo "🔗 Testing service connectivity..."

# Test PostgreSQL connection
if command -v pg_isready >/dev/null 2>&1; then
    echo "  → PostgreSQL: Testing connection to postgres:5432..."
    if timeout 5 pg_isready -h postgres -p 5432 >/dev/null 2>&1; then
        echo "  ✅ PostgreSQL: Connected"
    else
        echo "  ⚠️ PostgreSQL: Not available (postgres:5432)"
    fi
else
    echo "  → PostgreSQL: Client not installed, testing with ping..."
    if timeout 3 ping -c 1 postgres >/dev/null 2>&1; then
        echo "  ✅ PostgreSQL host: Reachable"
    else
        echo "  ⚠️ PostgreSQL host: Not reachable"
    fi
fi

# Test Qdrant connection
echo "  → Qdrant: Testing connection to qdrant:6333..."
if timeout 5 curl -sf http://qdrant:6333/health >/dev/null 2>&1; then
    echo "  ✅ Qdrant: Connected"
else
    echo "  ⚠️ Qdrant: Not available (qdrant:6333)"
fi

# Test LangGraph Server connection
echo "  → LangGraph Server: Testing connection to langgraph-server:2024..."
if timeout 5 curl -sf http://langgraph-server:2024/health >/dev/null 2>&1; then
    echo "  ✅ LangGraph Server: Connected"
else
    echo "  ⚠️ LangGraph Server: Not available (langgraph-server:2024)"
fi

# Test LangSmith connection
echo "  → LangSmith: Testing connection to langsmith:8000..."
if timeout 5 curl -sf http://langsmith:8000/health >/dev/null 2>&1; then
    echo "  ✅ LangSmith: Connected"
else
    echo "  ⚠️ LangSmith: Not available (langsmith:8000)"
fi

# 3) Test API connections if environment variables are available
if [ -n "${OPENAI_API_KEY:-}" ] || [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
    echo "🧪 Testing AI API connections..."
    
    # Check if test_apis.py exists and run it
    if [ -f "/opt/test_apis.py" ]; then
        cd /opt
        python3 test_apis.py
        cd /home/user/app
    else
        echo "  💡 API test script not available - run manually if needed"
    fi
else
    echo "🤖 No AI API keys configured - LangGraph will use default models"
fi

# 4) Display environment information
echo ""
echo "🎯 Development Environment Ready!"
echo "   Working Directory: $(pwd)"
echo "   Network: langgraph-network"
echo "   User: $(whoami)"
echo ""

# 5) Display helpful information
echo "📚 Quick Commands:"
echo "   langgraph --help           # View LangGraph CLI help"
echo "   langgraph new my-project   # Create new LangGraph project"  
echo "   langgraph dev              # Start development server"
echo "   curl http://langgraph-server:2024/health  # Test LangGraph API"
echo "   curl http://langsmith:8000/health         # Test LangSmith API"
echo "   curl http://qdrant:6333/health            # Test Qdrant API"
echo ""

echo "🌐 Service URLs (from host):"
echo "   LangGraph Studio: http://localhost:2024"
echo "   LangSmith UI:     http://localhost:8000"
echo "   Chat UI:          http://localhost:5173"
echo ""

echo "└─ Development environment initialized; dropping into shell ───────"

# 6) Drop into interactive bash with all environment variables available
exec /bin/bash -i