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

# Container uses .env file during runtime - secrets are already loaded

# 2) Test API connections using api_utils.py
echo "🧪 Testing API connections..."

# Check if api_utils.py exists and test APIs
if [ -f "/home/user/app/envs/setup/api_utils.py" ]; then
    echo "📡 Running comprehensive API validation..."
    cd /home/user/app
    python3 -c "
import sys
sys.path.append('envs/setup')
from api_utils import test_all_apis
test_all_apis()
"
else
    echo "⚠️  API utils not found - skipping API validation"
    echo "💡 Ensure envs/setup/api_utils.py exists for API testing"
fi

# 3) Check service health (optional - can be skipped with SKIP_HEALTH_CHECK=true)
if [ "${SKIP_HEALTH_CHECK:-false}" = "true" ]; then
    echo "🏥 Skipping service health checks (SKIP_HEALTH_CHECK=true)"
else
    echo "🏥 Checking service health..."

    if [ -f "/home/user/app/envs/test/agent-dev/service_health_check.sh" ]; then
        echo "🔍 Running service health checks..."
        /home/user/app/envs/test/agent-dev/service_health_check.sh check --quiet --timeout 3
        
        # Check return code and provide feedback
        service_check_result=$?
        if [ $service_check_result -eq 0 ]; then
            echo "✅ All services are healthy - ready for development!"
        elif [ $service_check_result -eq 1 ]; then
            echo "⚠️  Some services are not responding - they may still be starting up"
            echo "💡 Run: ./envs/test/agent-dev/service_health_check.sh status"
        else
            echo "🚨 Service health check failed - check if other services are running"
            echo "💡 Run: docker-compose -f envs/test/docker-compose.yml logs"
        fi
    else
        echo "⚠️  Service health check script not found"
        echo "💡 Ensure envs/test/agent-dev/service_health_check.sh exists"
    fi
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
echo "   langgraph --help                                      # View LangGraph CLI help"
echo "   langgraph new my-project                              # Create new LangGraph project"  
echo "   langgraph dev                                         # Start development server"
echo "   ./envs/test/agent-dev/service_health_check.sh status  # Check service status"
echo "   ./envs/test/agent-dev/integration_test.sh             # Run integration tests"
echo ""

echo "🔧 Internal Service URLs (from container):"
echo "   curl http://langgraph-server:2024/docs    # LangGraph API docs"
echo "   curl http://qdrant:6333/cluster           # Qdrant vector DB"
echo "   curl http://langfuse-web:3000             # Langfuse web interface"
echo "   curl http://clickhouse:8123/ping          # ClickHouse database"
echo ""

echo "🌐 External Service URLs (from host):"
echo "   LangGraph Server: http://localhost:2024"
echo "   Chat UI:          http://localhost:5173"
echo "   Qdrant:           http://localhost:6333"
echo "   pgAdmin:          http://localhost:8080"
echo "   RedisInsight:     http://localhost:8001"
echo "   Langfuse Web:     http://localhost:3000"
echo "   MinIO Console:    http://localhost:9191"
echo ""

echo "└─ Development environment initialized; dropping into shell ───────"

# 6) Drop into interactive bash with all environment variables available
exec /bin/bash -i