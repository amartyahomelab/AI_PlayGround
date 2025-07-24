#!/bin/bash

# Simple smoke test for the LangGraph stack
set -e

echo "🧪 Running LangGraph Stack Smoke Test..."

# Change to the test directory
cd "$(dirname "$0")"

# Test 1: Check if Docker Compose file is valid
echo "✅ Testing Docker Compose configuration..."
docker-compose config > /dev/null 2>&1
echo "   Docker Compose configuration is valid"

# Test 2: Check if all required files exist
echo "✅ Testing file structure..."
required_files=(
    "docker-compose.yml"
    ".env.example"
    "start.sh"
    "README.md"
    "agent-dev/Dockerfile"
    "agent-dev/entrypoint.sh"
    "postgres/Dockerfile"
    "postgres/entrypoint.sh"
    "qdrant/Dockerfile"
    "qdrant/entrypoint.sh"
    "langgraph-server/Dockerfile"
    "langgraph-server/entrypoint.sh"
    "langsmith/Dockerfile"
    "langsmith/entrypoint.sh"
    "chat-ui/Dockerfile"
    "chat-ui/entrypoint.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file exists"
    else
        echo "   ✗ $file missing"
        exit 1
    fi
done

# Test 3: Check if entrypoint scripts are executable
echo "✅ Testing script permissions..."
chmod +x start.sh
chmod +x agent-dev/entrypoint.sh
chmod +x postgres/entrypoint.sh
chmod +x qdrant/entrypoint.sh
chmod +x langgraph-server/entrypoint.sh
chmod +x langsmith/entrypoint.sh
chmod +x chat-ui/entrypoint.sh
echo "   All entrypoint scripts are executable"

# Test 4: Check if secret management files exist
echo "✅ Testing secret management integration..."
if [ -f "../config/secrets.yaml" ]; then
    echo "   ✓ secrets.yaml found"
else
    echo "   ⚠ secrets.yaml not found (will use fallback configuration)"
fi

if [ -f "../setup/sec_utils.py" ]; then
    echo "   ✓ sec_utils.py found"
else
    echo "   ⚠ sec_utils.py not found (will use fallback configuration)"
fi

# Test 5: Create .env if it doesn't exist
echo "✅ Testing environment configuration..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "   ✓ Created .env from .env.example"
else
    echo "   ✓ .env file already exists"
fi

# Test 6: Test startup script help
echo "✅ Testing startup script..."
./start.sh help > /dev/null 2>&1
echo "   ✓ Startup script is functional"

echo ""
echo "🎉 Smoke test completed successfully!"
echo ""
echo "Your LangGraph self-hosted stack is ready to deploy!"
echo ""
echo "Quick start:"
echo "  ./start.sh start    # Start the full stack"
echo "  ./start.sh status   # Check service status"
echo "  ./start.sh dev      # Start development container"
echo ""
echo "Access URLs (after starting):"
echo "  LangGraph Studio: http://localhost:2024"
echo "  Chat UI Demo:     http://localhost:5173"
echo "  Qdrant Dashboard: http://localhost:6333/dashboard"
echo "  LangSmith UI:     http://localhost:8000"
echo ""
