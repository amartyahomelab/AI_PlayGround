#!/bin/bash

# LangGraph Self-Hosted Stack Startup Script
# This script helps you start and manage the LangGraph stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${PURPLE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test endpoint function
test_endpoint() {
    local url=$1
    local service_name=$2
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 10 "$url" > /dev/null 2>&1; then
            print_success "$service_name is accessible at $url"
            return 0
        else
            if [ $attempt -eq $max_attempts ]; then
                print_error "$service_name is not accessible at $url"
                return 1
            else
                echo "   Attempt $attempt failed, retrying..."
                sleep 2
            fi
        fi
        ((attempt++))
    done
}

# Show banner with service information
show_banner() {
    echo ""
    echo -e "${PURPLE}================================================${NC}"
    echo -e "${PURPLE}🎯 LangGraph Self-Hosted Stack${NC}"
    echo -e "${PURPLE}================================================${NC}"
    echo ""
    
    print_header "🚀 Ready-to-Use Access Points"
    echo ""
    echo -e "${CYAN}🎨 LangGraph Studio:${NC}  http://localhost:2024"
    echo -e "   ${NC}Build & test agents visually (includes chat interface)${NC}"
    echo ""
    echo -e "${CYAN}🔍 Qdrant Dashboard:${NC}   http://localhost:6333/dashboard"
    echo -e "   ${NC}Vector database management${NC}"
    echo ""
    echo -e "${CYAN}📈 LangSmith Tracing:${NC}  http://localhost:8000"
    echo -e "   ${NC}Execution monitoring & analytics${NC}"
    echo ""
    echo -e "${CYAN}🔧 RedisInsight:${NC}       http://localhost:8001"
    echo -e "   ${NC}Redis GUI & management${NC}"
    echo ""
    echo -e "${CYAN}🗄️  pgAdmin:${NC}           http://localhost:8080"
    echo -e "   ${NC}PostgreSQL GUI & management${NC}"
    echo ""
    echo -e "${CYAN}🐘 PostgreSQL:${NC}        localhost:5432"
    echo -e "   ${NC}Direct database connection${NC}"
    echo ""
    echo -e "${CYAN}📊 Redis:${NC}             localhost:6379"
    echo -e "   ${NC}Caching & session management${NC}"
    echo ""
    
    print_info "Run './start.sh dev' to start the agent development container"
    print_info "Run './start.sh logs <service>' to view specific service logs"
}

# Show service status
show_status() {
    echo ""
    print_header "📊 Service Status"
    echo ""
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running"
        exit 1
    fi

    # List running containers
    echo "Running containers:"
    docker ps --filter "label=com.docker.compose.project=langgraph-stack" \
        --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
    echo ""
}

# Start all services
start_services() {
    print_header "🚀 Starting LangGraph Stack..."
    echo ""
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        print_error ".env file not found!"
        print_info "Please copy secrets_example.yaml to secrets.yaml and run the setup script"
        exit 1
    fi

    # Start the stack
    print_info "Starting all services..."
    docker compose -p langgraph-stack up -d

    echo ""
    print_success "All services started!"
    
    # Wait a moment for services to initialize
    print_info "Waiting for services to initialize..."
    sleep 10
    
    # Show status
    show_status
    
    # Show banner
    show_banner
}

# Stop all services
stop_services() {
    print_header "🛑 Stopping LangGraph Stack..."
    echo ""
    
    docker compose -p langgraph-stack down
    
    print_success "All services stopped!"
}

# Restart all services
restart_services() {
    print_header "🔄 Restarting LangGraph Stack..."
    echo ""
    
    stop_services
    echo ""
    start_services
}

# Verify all endpoints
verify_endpoints() {
    print_header "🔍 Verifying All Endpoints"
    echo ""
    
    local total_endpoints=8
    local successful_tests=0
    
    # Web interfaces
    if test_endpoint "http://localhost:2024" "LangGraph Studio"; then
        ((successful_tests++))
    fi
    
    if test_endpoint "http://localhost:6333/dashboard" "Qdrant Dashboard"; then
        ((successful_tests++))
    fi
    
    if test_endpoint "http://localhost:8000" "LangSmith Tracing"; then
        ((successful_tests++))
    fi
    
    if test_endpoint "http://localhost:8001" "RedisInsight"; then
        ((successful_tests++))
    fi
    
    if test_endpoint "http://localhost:8080" "pgAdmin"; then
        ((successful_tests++))
    fi
    
    # Database connections (simplified check)
    if nc -z localhost 5432 2>/dev/null; then
        print_success "PostgreSQL is accessible at localhost:5432"
        ((successful_tests++))
    else
        print_error "PostgreSQL is not accessible at localhost:5432"
    fi
    
    if nc -z localhost 6379 2>/dev/null; then
        print_success "Redis is accessible at localhost:6379"
        ((successful_tests++))
    else
        print_error "Redis is not accessible at localhost:6379"
    fi
    
    if nc -z localhost 6333 2>/dev/null; then
        print_success "Qdrant is accessible at localhost:6333"
        ((successful_tests++))
    else
        print_error "Qdrant is not accessible at localhost:6333"
    fi
    
    echo ""
    print_header "📊 Verification Summary"
    echo ""
    
    if [ $successful_tests -eq $total_endpoints ]; then
        print_success "All $total_endpoints endpoints are working! 🎉"
        echo ""
        print_info "Your LangGraph stack is fully operational!"
    else
        print_warning "$successful_tests/$total_endpoints endpoints are working"
        echo ""
        print_info "Some services may still be starting up. Try running verification again in a few moments."
    fi
}

# Show logs for a specific service
show_logs() {
    local service=${1:-""}
    
    if [ -z "$service" ]; then
        print_error "Please specify a service name"
        print_info "Available services: api, langsmith, postgres, redis, qdrant, redisinsight, pgadmin"
        exit 1
    fi
    
    local container_name="langgraph-$service"
    
    print_header "📋 Logs for $service"
    echo ""
    
    if docker ps --filter "name=$container_name" --format '{{.Names}}' | grep -q "$container_name"; then
        docker logs -f "$container_name"
    else
        print_error "Container $container_name is not running"
        exit 1
    fi
}

# Start development container
start_dev() {
    print_header "🛠️  Starting Development Environment"
    echo ""
    
    print_info "Starting agent development container..."
    docker compose -p langgraph-stack up agent-dev -d
    
    print_success "Development container started!"
    print_info "Access it with: docker exec -it langgraph-agent-dev bash"
}

# Show help
show_help() {
    echo ""
    echo -e "${PURPLE}LangGraph Stack Management Script${NC}"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|verify|logs|dev|help}"
    echo ""
    echo "Commands:"
    echo "  start    - Start all services"
    echo "  stop     - Stop all services"
    echo "  restart  - Restart all services"
    echo "  status   - Show current service status"
    echo "  verify   - Test all endpoints"
    echo "  logs     - Show logs for a specific service"
    echo "  dev      - Start development container"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs api"
    echo "  $0 verify"
    echo ""
}

# Main script logic
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        show_banner
        ;;
    verify)
        verify_endpoints
        ;;
    logs)
        show_logs "$2"
        ;;
    dev)
        start_dev
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
