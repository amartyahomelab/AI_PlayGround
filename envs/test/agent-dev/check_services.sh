#!/bin/bash

# Service Health Check Script
# Tests all services from both docker-compose files and their integrations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f "/home/user/app/envs/test/.env" ]; then
    source /home/user/app/envs/test/.env
    echo "📋 Environment variables loaded from .env file"
else
    echo "⚠️  .env file not found, using system environment"
fi

# Service endpoints and their health check URLs
declare -A SERVICES=(
    # LangGraph Stack Services (from envs/test/docker-compose.yml)
    ["qdrant"]="http://qdrant:6333/cluster"
    ["langgraph-server"]="http://langgraph-server:2024/docs"
    ["chat-ui"]="http://chat-ui:3000"
    ["pgadmin"]="http://pgadmin/misc/ping"
    ["redisinsight"]="http://redisinsight:8001"
    
    # Langfuse Stack Services (from langfuse/docker-compose.yml)
    ["langfuse-web"]="http://langfuse-web:3000"
    ["langfuse-worker"]="http://langfuse-worker:3030"
    ["postgres"]="postgresql://postgres:5432"
    ["redis"]="redis://redis:6379"
    ["clickhouse"]="http://clickhouse:8123/ping"
    ["minio"]="http://minio:9000/minio/health/live"
)

# Service port mappings for external access
declare -A SERVICE_PORTS=(
    ["qdrant"]="6333"
    ["langgraph-server"]="2024"
    ["chat-ui"]="5173"
    ["pgadmin"]="8080"
    ["redisinsight"]="8001"
    ["langfuse-web"]="3000"
    ["postgres"]="5432"
    ["redis"]="6379"
    ["clickhouse"]="8123"
    ["minio"]="9190"
)

# Function to check HTTP endpoint
check_http_endpoint() {
    local service_name="$1"
    local url="$2"
    local timeout=10
    
    if timeout $timeout curl -sf "$url" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $service_name${NC}: HTTP endpoint responding"
        return 0
    else
        echo -e "  ${RED}❌ $service_name${NC}: HTTP endpoint not responding"
        return 1
    fi
}

# Function to check PostgreSQL
check_postgres() {
    local service_name="$1"
    local timeout=10
    
    if timeout $timeout pg_isready -h postgres -p 5432 -U postgres >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $service_name${NC}: PostgreSQL database responding"
        return 0
    else
        echo -e "  ${RED}❌ $service_name${NC}: PostgreSQL database not responding"
        return 1
    fi
}

# Function to check Redis
check_redis() {
    local service_name="$1"
    local timeout=10
    local redis_password="${REDIS_AUTH:-myStrongRedisPassword123!}"
    
    if timeout $timeout redis-cli -h redis -p 6379 -a "$redis_password" ping >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $service_name${NC}: Redis responding"
        return 0
    else
        echo -e "  ${RED}❌ $service_name${NC}: Redis not responding"
        return 1
    fi
}

# Function to check service integration
check_integration() {
    local service1="$1"
    local service2="$2"
    local integration_type="$3"
    
    case "$integration_type" in
        "langfuse-auth")
            # Test Langfuse authentication
            local public_key="${LANGFUSE_PUBLIC_KEY:-pk-lf-ba140549-1366-4227-811d-af5549f42001}"
            local secret_key="${LANGFUSE_SECRET_KEY:-sk-lf-0ab9b242-0f5b-4fd3-af2b-21f5cb3b9cec}"
            
            if curl -sf -X POST "http://langfuse-web:3000/api/public/auth/check" \
                -H "Authorization: Bearer $public_key" >/dev/null 2>&1; then
                echo -e "    ${GREEN}✅ Integration${NC}: $service1 ↔ $service2 (Auth check passed)"
                return 0
            else
                echo -e "    ${YELLOW}⚠️  Integration${NC}: $service1 ↔ $service2 (Auth check failed - may need setup)"
                return 1
            fi
            ;;
        "langgraph-qdrant")
            # Test LangGraph to Qdrant connection
            if curl -sf "http://langgraph-server:2024/health" | grep -q "qdrant" 2>/dev/null; then
                echo -e "    ${GREEN}✅ Integration${NC}: $service1 ↔ $service2 (Vector DB connection active)"
                return 0
            else
                echo -e "    ${YELLOW}⚠️  Integration${NC}: $service1 ↔ $service2 (Connection status unknown)"
                return 1
            fi
            ;;
        "chat-langgraph")
            # Test Chat UI to LangGraph Server connection
            if curl -sf "http://chat-ui:3000/api/health" >/dev/null 2>&1; then
                echo -e "    ${GREEN}✅ Integration${NC}: $service1 ↔ $service2 (API connection active)"
                return 0
            else
                echo -e "    ${YELLOW}⚠️  Integration${NC}: $service1 ↔ $service2 (Connection status unknown)"
                return 1
            fi
            ;;
        *)
            echo -e "    ${BLUE}ℹ️  Integration${NC}: $service1 ↔ $service2 (No specific test defined)"
            return 0
            ;;
    esac
}

# Main health check function
main() {
    echo "🔍 Starting comprehensive service health check..."
    echo ""
    
    local total_services=0
    local healthy_services=0
    local failed_services=()
    
    # Check each service
    for service in "${!SERVICES[@]}"; do
        total_services=$((total_services + 1))
        local url="${SERVICES[$service]}"
        local success=false
        
        echo -e "${BLUE}🔍 Checking $service${NC}..."
        
        case "$service" in
            "postgres")
                if check_postgres "$service"; then
                    success=true
                fi
                ;;
            "redis")
                if check_redis "$service"; then
                    success=true
                fi
                ;;
            *)
                if check_http_endpoint "$service" "$url"; then
                    success=true
                fi
                ;;
        esac
        
        if $success; then
            healthy_services=$((healthy_services + 1))
            # Show external access info if available
            if [[ -n "${SERVICE_PORTS[$service]:-}" ]]; then
                echo -e "    ${BLUE}🌐 External access${NC}: http://localhost:${SERVICE_PORTS[$service]}"
            fi
        else
            failed_services+=("$service")
        fi
        echo ""
    done
    
    # Integration tests
    echo -e "${BLUE}🔗 Testing service integrations...${NC}"
    echo ""
    
    # Only run integration tests if base services are healthy
    if [[ $healthy_services -gt 4 ]]; then
        check_integration "langfuse-web" "postgres" "langfuse-auth"
        check_integration "langgraph-server" "qdrant" "langgraph-qdrant"
        check_integration "chat-ui" "langgraph-server" "chat-langgraph"
    else
        echo -e "  ${YELLOW}⚠️  Skipping integration tests (too many services down)${NC}"
    fi
    
    echo ""
    echo "📊 Health Check Summary:"
    echo "========================"
    echo -e "Total services: $total_services"
    echo -e "Healthy services: ${GREEN}$healthy_services${NC}"
    echo -e "Failed services: ${RED}$((total_services - healthy_services))${NC}"
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}❌ Failed services:${NC}"
        for failed_service in "${failed_services[@]}"; do
            echo -e "  - $failed_service"
        done
    fi
    
    echo ""
    
    # Overall status
    if [[ $healthy_services -eq 0 ]]; then
        echo -e "${RED}🚨 No services are running${NC}"
        echo "💡 Start services with: docker-compose up -d"
        return 2
    elif [[ $healthy_services -eq $total_services ]]; then
        echo -e "${GREEN}🎉 All services are healthy!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some services are not responding${NC}"
        echo "💡 Check docker-compose logs for failed services"
        return 1
    fi
}

# Run the health check
main "$@"
