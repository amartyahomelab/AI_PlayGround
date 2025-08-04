#!/bin/bash

# Service health check script for docker-compose services
# Provides quick health checks for all compose services

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Configuration
DEFAULT_COMPOSE_FILE="envs/test/docker-compose.yml"
COMPOSE_FILE="${COMPOSE_FILE:-$DEFAULT_COMPOSE_FILE}"
TIMEOUT="${TIMEOUT:-5}"  # Much shorter timeout for internal network
QUIET="${QUIET:-false}"
MODE="${MODE:-guest}"  # Default to guest (container) mode

# Function to configure services based on mode and compose file
configure_services() {
    if [ "$COMPOSE_FILE" = "envs/test/docker-compose.yml" ] || [ "$COMPOSE_FILE" = "/workspace/envs/test/docker-compose.yml" ]; then
        if [ "$MODE" = "host" ]; then
            declare -g -A SERVICES=(
                ["qdrant"]="localhost:6333:/cluster"
                ["pgadmin"]="localhost:8080:/misc/ping"
                ["langgraph-server"]="localhost:2024:/docs"
                ["redisinsight"]="localhost:8001:/"
                ["chat-ui"]="localhost:5173:/"
            )
            log_context="from host machine (main stack)"
        else
            declare -g -A SERVICES=(
                ["qdrant"]="qdrant:6333:/cluster"
                ["pgadmin"]="pgadmin:80:/misc/ping"
                ["langgraph-server"]="langgraph-server:2024:/docs"
                ["redisinsight"]="redisinsight:8001:/"
                ["chat-ui"]="chat-ui:3000:/"
            )
            log_context="from container (guest, main stack)"
        fi
    elif [ "$COMPOSE_FILE" = "langfuse/docker-compose.yml" ]; then
        # Example mapping for langfuse stack (update as needed)
        if [ "$MODE" = "host" ]; then
            declare -g -A SERVICES=(
                ["langfuse-web"]="localhost:3000:/"
                ["langfuse-worker"]="localhost:3030:/"
                ["clickhouse"]="localhost:8123:/ping"
                ["minio"]="localhost:9000:/minio/health/live"
                ["redis"]="localhost:6379:/"
                ["postgres"]="localhost:5432:/"
            )
            log_context="from host machine (langfuse stack)"
        else
            declare -g -A SERVICES=(
                ["langfuse-web"]="langfuse-web:3000:/"
                ["langfuse-worker"]="langfuse-worker:3030:/"
                ["clickhouse"]="clickhouse:8123:/ping"
                ["minio"]="minio:9000:/minio/health/live"
                ["redis"]="redis:6379:/"
                ["postgres"]="postgres:5432:/"
            )
            log_context="from container (guest, langfuse stack)"
        fi
    else
        log_context="custom compose file: $COMPOSE_FILE (service mapping may be wrong!)"
        # Default to main stack mapping, but warn user
        if [ "$MODE" = "host" ]; then
            declare -g -A SERVICES=(
                ["qdrant"]="localhost:6333:/cluster"
                ["pgadmin"]="localhost:8080:/misc/ping"
                ["langgraph-server"]="localhost:2024:/docs"
                ["redisinsight"]="localhost:8001:/"
                ["chat-ui"]="localhost:5173:/"
            )
        else
            declare -g -A SERVICES=(
                ["qdrant"]="qdrant:6333:/cluster"
                ["pgadmin"]="pgadmin:80:/misc/ping"
                ["langgraph-server"]="langgraph-server:2024:/docs"
                ["redisinsight"]="redisinsight:8001:/"
                ["chat-ui"]="chat-ui:3000:/"
            )
        fi
        echo "⚠️  Warning: Service mapping may not match $COMPOSE_FILE. Edit script to add correct mapping."
    fi
    echo "ℹ️  Using compose file: $COMPOSE_FILE"
}

# Function to print messages (respects quiet mode)
log_message() {
    local level="$1"
    local message="$2"
    
    if [ "$QUIET" != "true" ]; then
        case $level in
            "INFO")
                echo -e "${BLUE}ℹ️  $message${NC}"
                ;;
            "SUCCESS")
                echo -e "${GREEN}✅ $message${NC}"
                ;;
            "WARNING")
                echo -e "${YELLOW}⚠️  $message${NC}"
                ;;
            "ERROR")
                echo -e "${RED}❌ $message${NC}"
                ;;
            *)
                echo "$message"
                ;;
        esac
    fi
}

# Function to check if a service is responding
check_service_health() {
    local service_name="$1"
    local endpoint_config="$2"
    
    # Parse endpoint configuration (format: host:port:path)
    local host=$(echo "$endpoint_config" | cut -d':' -f1)
    local port=$(echo "$endpoint_config" | cut -d':' -f2)
    local path=$(echo "$endpoint_config" | cut -d':' -f3-)
    
    log_message "INFO" "Checking $service_name at http://$host:$port$path"
    
    local count=0
    while [ $count -lt $TIMEOUT ]; do
        if curl -s -f --connect-timeout 2 "http://$host:$port$path" >/dev/null 2>&1; then
            log_message "SUCCESS" "$service_name is healthy"
            return 0
        fi
        
        if [ "$QUIET" != "true" ] && [ $((count % 10)) -eq 0 ] && [ $count -gt 0 ]; then
            log_message "INFO" "Still waiting for $service_name... (${count}s/${TIMEOUT}s)"
        fi
        
        sleep 1
        ((count++))
    done
    
    log_message "ERROR" "$service_name is not responding after ${TIMEOUT}s"
    return 1
}

# Function to check if Docker Compose services are running
check_compose_services() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_message "ERROR" "Docker compose file not found: $COMPOSE_FILE"
        return 1
    fi
    
    log_message "INFO" "Checking Docker Compose services..."
    
    local running_services=$(docker-compose -f "$COMPOSE_FILE" ps --services --filter "status=running" 2>/dev/null)
    local total_services=$(docker-compose -f "$COMPOSE_FILE" config --services 2>/dev/null)
    
    if [ -z "$running_services" ]; then
        log_message "WARNING" "No services are currently running"
        return 1
    fi
    
    local running_count=$(echo "$running_services" | wc -l)
    local total_count=$(echo "$total_services" | wc -l)
    
    log_message "INFO" "Docker Compose status: $running_count/$total_count services running"
    
    if [ "$running_count" -eq "$total_count" ]; then
        log_message "SUCCESS" "All Docker Compose services are running"
        return 0
    else
        log_message "WARNING" "Some services are not running"
        return 1
    fi
}

# Function to perform quick health check on all services
quick_health_check() {
    local failed_services=()
    local success_count=0
    
    log_message "INFO" "Performing quick health checks $log_context..."
    
    for service in "${!SERVICES[@]}"; do
        if check_service_health "$service" "${SERVICES[$service]}"; then
            ((success_count++))
        else
            failed_services+=("$service")
        fi
    done
    
    local total_services=${#SERVICES[@]}
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_message "SUCCESS" "All $total_services services are healthy! 🎉"
        return 0
    else
        log_message "ERROR" "Health check failed for: ${failed_services[*]}"
        log_message "INFO" "Healthy services: $success_count/$total_services"
        return 1
    fi
}

# Function to wait for all services to be ready
wait_for_all_services() {
    log_message "INFO" "Waiting for all services to be ready..."
    
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_message "INFO" "Attempt $attempt/$max_attempts"
        
        if quick_health_check; then
            log_message "SUCCESS" "All services are ready!"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_message "INFO" "Waiting 10 seconds before retry..."
            sleep 10
        fi
        
        ((attempt++))
    done
    
    log_message "ERROR" "Failed to verify all services after $max_attempts attempts"
    return 1
}

# Function to show service status
show_service_status() {
    log_message "INFO" "Service Status Overview ($log_context):"
    echo "=================================="
    
    for service in "${!SERVICES[@]}"; do
        local endpoint_config="${SERVICES[$service]}"
        local host=$(echo "$endpoint_config" | cut -d':' -f1)
        local port=$(echo "$endpoint_config" | cut -d':' -f2)
        local path=$(echo "$endpoint_config" | cut -d':' -f3-)
        
        if curl -s -f --connect-timeout 2 "http://$host:$port$path" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service${NC} - http://$host:$port$path"
        else
            echo -e "${RED}❌ $service${NC} - http://$host:$port$path"
        fi
    done
    
    echo "=================================="
}

# Function to display help
show_help() {
    echo "Service Health Check Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  check         Perform quick health check on all services (default)"
    echo "  wait          Wait for all services to become ready"
    echo "  status        Show current status of all services"
    echo "  compose       Check Docker Compose service status"
    echo "  help          Show this help message"
    echo ""
    echo "Options:"
    echo "  --quiet       Suppress output messages (useful for scripts)"
    echo "  --timeout N   Set timeout in seconds (default: 5)"
    echo "  --mode MODE   Set execution mode: 'host' or 'guest' (default: guest)"
    echo "  --compose-file PATH   Path to docker-compose.yml file"
    echo ""
    echo "Environment Variables:"
    echo "  COMPOSE_FILE  Path to docker-compose.yml file"
    echo "  TIMEOUT       Timeout in seconds for health checks"
    echo "  QUIET         Set to 'true' to suppress output"
    echo "  MODE          Execution mode: 'host' or 'guest'"
    echo ""
    echo "Examples:"
    echo "  $0 check                    # Quick health check (guest mode)"
    echo "  $0 check --mode host        # Quick health check from host"
    echo "  $0 wait --timeout 60        # Wait up to 60 seconds"
    echo "  $0 status --mode host       # Show status from host machine"
    echo "  $0 compose                  # Check Docker Compose status"
}

# Parse command line arguments
COMMAND="check"
while [[ $# -gt 0 ]]; do
    case $1 in
        check|wait|status|compose|help)
            COMMAND="$1"
            shift
            ;;
        --quiet)
            QUIET="true"
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            if [ "$MODE" != "host" ] && [ "$MODE" != "guest" ]; then
                echo "Error: Mode must be 'host' or 'guest'"
                exit 1
            fi
            shift 2
            ;;
        --compose-file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -h|--help)
            COMMAND="help"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Configure services based on mode (after argument parsing)
configure_services

# Execute the requested command
case $COMMAND in
    "check")
        quick_health_check
        exit $?
        ;;
    "wait")
        wait_for_all_services
        exit $?
        ;;
    "status")
        show_service_status
        exit 0
        ;;
    "compose")
        check_compose_services
        exit $?
        ;;
    "help")
        show_help
        exit 0
        ;;
    *)
        echo "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
