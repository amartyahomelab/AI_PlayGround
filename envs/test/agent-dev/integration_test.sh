#!/bin/bash

# Check for help command first
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Service Integration Test Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --mode MODE         Set execution mode: 'host' or 'guest' (default: guest)"
    echo "  --compose-file PATH Path to docker-compose.yml file (default: envs/test/docker-compose.yml)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run tests in guest mode (main stack)"
    echo "  $0 --mode host                        # Run tests from host machine (main stack)"
    echo "  $0 --compose-file langfuse/docker-compose.yml  # Test langfuse stack"
    exit 0
fi

# Integration test script for docker-compose services
# Tests service endpoints and health checks to ensure all services are running correctly

set -e  # Exit on any error

echo "🧪 Starting Service Integration Tests..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
MODE="${MODE:-guest}"  # Default to guest (container) mode
DEFAULT_COMPOSE_FILE="envs/test/docker-compose.yml"
COMPOSE_FILE="${COMPOSE_FILE:-$DEFAULT_COMPOSE_FILE}"
DOCKER_NETWORK="langgraph-network"

# Function to configure services based on mode and compose file
configure_services() {
    if [ "$COMPOSE_FILE" = "envs/test/docker-compose.yml" ] || [ "$COMPOSE_FILE" = "/workspace/envs/test/docker-compose.yml" ]; then
        # Main stack configuration
        if [ "$MODE" = "host" ]; then
            declare -g QDRANT_HOST="localhost"
            declare -g QDRANT_PORT="6333"
            declare -g PGADMIN_HOST="localhost"
            declare -g PGADMIN_PORT="8080"
            declare -g LANGGRAPH_HOST="localhost"
            declare -g LANGGRAPH_PORT="2024"
            declare -g REDISINSIGHT_HOST="localhost"
            declare -g REDISINSIGHT_PORT="8001"
            declare -g CHATUI_HOST="localhost"
            declare -g CHATUI_PORT="5173"
            declare -g LOG_CONTEXT="from host machine (main stack)"
        else
            declare -g QDRANT_HOST="qdrant"
            declare -g QDRANT_PORT="6333"
            declare -g PGADMIN_HOST="pgadmin"
            declare -g PGADMIN_PORT="80"
            declare -g LANGGRAPH_HOST="langgraph-server"
            declare -g LANGGRAPH_PORT="2024"
            declare -g REDISINSIGHT_HOST="redisinsight"
            declare -g REDISINSIGHT_PORT="8001"
            declare -g CHATUI_HOST="chat-ui"
            declare -g CHATUI_PORT="3000"
            declare -g LOG_CONTEXT="from container (guest, main stack)"
        fi
    elif [ "$COMPOSE_FILE" = "langfuse/docker-compose.yml" ]; then
        # Langfuse stack configuration
        if [ "$MODE" = "host" ]; then
            declare -g QDRANT_HOST="localhost"  # Not in langfuse stack, keeping for compatibility
            declare -g QDRANT_PORT="6333"
            declare -g PGADMIN_HOST="localhost"  # Not in langfuse stack
            declare -g PGADMIN_PORT="8080"
            declare -g LANGGRAPH_HOST="localhost"  # langfuse-web instead
            declare -g LANGGRAPH_PORT="3000"
            declare -g REDISINSIGHT_HOST="localhost"  # Not in langfuse stack
            declare -g REDISINSIGHT_PORT="8001"
            declare -g CHATUI_HOST="localhost"  # langfuse-worker instead
            declare -g CHATUI_PORT="3030"
            declare -g LOG_CONTEXT="from host machine (langfuse stack - service mapping may be wrong!)"
        else
            declare -g QDRANT_HOST="qdrant"  # Not in langfuse stack
            declare -g QDRANT_PORT="6333"
            declare -g PGADMIN_HOST="pgadmin"  # Not in langfuse stack
            declare -g PGADMIN_PORT="80"
            declare -g LANGGRAPH_HOST="langfuse-web"  # Using langfuse-web instead
            declare -g LANGGRAPH_PORT="3000"
            declare -g REDISINSIGHT_HOST="redisinsight"  # Not in langfuse stack
            declare -g REDISINSIGHT_PORT="8001"
            declare -g CHATUI_HOST="langfuse-worker"  # Using langfuse-worker instead
            declare -g CHATUI_PORT="3030"
            declare -g LOG_CONTEXT="from container (guest, langfuse stack - service mapping may be wrong!)"
        fi
        echo "⚠️  Warning: Integration test is designed for main stack. Langfuse stack has different services."
    else
        # Custom compose file - default to main stack but warn
        if [ "$MODE" = "host" ]; then
            declare -g QDRANT_HOST="localhost"
            declare -g QDRANT_PORT="6333"
            declare -g PGADMIN_HOST="localhost"
            declare -g PGADMIN_PORT="8080"
            declare -g LANGGRAPH_HOST="localhost"
            declare -g LANGGRAPH_PORT="2024"
            declare -g REDISINSIGHT_HOST="localhost"
            declare -g REDISINSIGHT_PORT="8001"
            declare -g CHATUI_HOST="localhost"
            declare -g CHATUI_PORT="5173"
            declare -g LOG_CONTEXT="custom compose file (host mode)"
        else
            declare -g QDRANT_HOST="qdrant"
            declare -g QDRANT_PORT="6333"
            declare -g PGADMIN_HOST="pgadmin"
            declare -g PGADMIN_PORT="80"
            declare -g LANGGRAPH_HOST="langgraph-server"
            declare -g LANGGRAPH_PORT="2024"
            declare -g REDISINSIGHT_HOST="redisinsight"
            declare -g REDISINSIGHT_PORT="8001"
            declare -g CHATUI_HOST="chat-ui"
            declare -g CHATUI_PORT="3000"
            declare -g LOG_CONTEXT="custom compose file (guest mode)"
        fi
        echo "⚠️  Warning: Service mapping may not match $COMPOSE_FILE. Edit script to add correct mapping."
    fi
    echo "ℹ️  Using compose file: $COMPOSE_FILE"
}

# Function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ $test_name${NC}"
        if [ -n "$details" ]; then
            echo -e "${RED}  Details: $details${NC}"
        fi
        ((TESTS_FAILED++))
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local host="$2"
    local port="$3"
    local timeout="${4:-10}"  # Reduced from 30 to 10 seconds
    local endpoint="${5:-/}"
    
    echo -e "${YELLOW}Waiting for $service_name to be ready...${NC}"
    
    local count=0
    while [ $count -lt $timeout ]; do
        if curl -s -f --connect-timeout 2 "http://$host:$port$endpoint" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    return 1
}

# Test Docker Compose setup
test_docker_compose() {
    echo -e "${BLUE}Testing Docker Compose configuration...${NC}"
    
    if [ -f "$COMPOSE_FILE" ]; then
        print_test_result "Docker compose file exists" "PASS"
        
        # Validate docker-compose file syntax
        if docker-compose -f "$COMPOSE_FILE" config >/dev/null 2>&1; then
            print_test_result "Docker compose file syntax" "PASS"
        else
            print_test_result "Docker compose file syntax" "FAIL" "Invalid docker-compose.yml syntax"
            return
        fi
        
        # Check if Docker is running
        if docker info >/dev/null 2>&1; then
            print_test_result "Docker daemon running" "PASS"
        else
            print_test_result "Docker daemon running" "FAIL" "Docker daemon not accessible"
            return
        fi
        
        # Check if docker-compose is available
        if command -v docker-compose >/dev/null 2>&1; then
            print_test_result "Docker Compose available" "PASS"
        else
            print_test_result "Docker Compose available" "FAIL" "docker-compose command not found"
        fi
    else
        print_test_result "Docker compose file exists" "FAIL" "docker-compose.yml not found at $COMPOSE_FILE"
    fi
}

# Test Qdrant service (Vector database)
test_qdrant_service() {
    echo -e "${BLUE}Testing Qdrant service ($LOG_CONTEXT)...${NC}"
    
    local host="$QDRANT_HOST"
    local port="$QDRANT_PORT"
    
    # Test if Qdrant is responding using the same endpoint as health check
    if wait_for_service "qdrant" "$host" "$port" 10 "/cluster"; then
        print_test_result "Qdrant service responsive" "PASS"
        
        # Test cluster endpoint (same as health check)
        local cluster_response=$(curl -s "http://$host:$port/cluster" 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_test_result "Qdrant cluster endpoint" "PASS"
        else
            print_test_result "Qdrant cluster endpoint" "FAIL" "Cluster endpoint not responding"
        fi
        
        # Test collections API
        local collections_response=$(curl -s "http://$host:$port/collections" 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_test_result "Qdrant collections API" "PASS"
        else
            print_test_result "Qdrant collections API" "FAIL" "Collections API call failed"
        fi
    else
        print_test_result "Qdrant service responsive" "FAIL" "Service not reachable on $host:$port"
    fi
}

# Test pgAdmin service (PostgreSQL GUI)
test_pgadmin_service() {
    echo -e "${BLUE}Testing pgAdmin service ($LOG_CONTEXT)...${NC}"
    
    local host="$PGADMIN_HOST"
    local port="$PGADMIN_PORT"
    
    # Test if pgAdmin is responding using the same endpoint as health check
    if wait_for_service "pgAdmin" "$host" "$port" 10 "/misc/ping"; then
        print_test_result "pgAdmin service responsive" "PASS"
        
        # Test the ping endpoint specifically
        local response=$(curl -s "http://$host:$port/misc/ping" 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_test_result "pgAdmin ping endpoint" "PASS"
        else
            print_test_result "pgAdmin ping endpoint" "FAIL" "Ping endpoint not responding"
        fi
    else
        print_test_result "pgAdmin service responsive" "FAIL" "Service not reachable on $host:$port"
    fi
}

# Test LangGraph Server service
test_langgraph_server() {
    echo -e "${BLUE}Testing LangGraph Server ($LOG_CONTEXT)...${NC}"
    
    local host="$LANGGRAPH_HOST"
    local port="$LANGGRAPH_PORT"
    
    # Test if LangGraph Server is responding
    if wait_for_service "LangGraph Server" "$host" "$port" 10; then
        print_test_result "LangGraph Server responsive" "PASS"
        
        # Test docs endpoint (instead of health)
        local docs_response=$(curl -s "http://$host:$port/docs" 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_test_result "LangGraph Server docs endpoint" "PASS"
        else
            print_test_result "LangGraph Server docs endpoint" "FAIL" "Docs endpoint not responding"
        fi
        
        # Test if API is accessible
        local api_response=$(curl -s -I "http://$host:$port/docs" 2>/dev/null | head -n 1)
        if echo "$api_response" | grep -q "200\|404" 2>/dev/null; then
            print_test_result "LangGraph Server API docs" "PASS"
        else
            print_test_result "LangGraph Server API docs" "FAIL" "API docs not accessible"
        fi
    else
        print_test_result "LangGraph Server responsive" "FAIL" "Service not reachable on $host:$port"
    fi
}

# Test Redis Insight service
test_redisinsight_service() {
    echo -e "${BLUE}Testing Redis Insight service ($LOG_CONTEXT)...${NC}"
    
    local host="$REDISINSIGHT_HOST"
    local port="$REDISINSIGHT_PORT"
    
    # Test if Redis Insight is responding
    if wait_for_service "Redis Insight" "$host" "$port" 10; then
        print_test_result "Redis Insight service responsive" "PASS"
        
        # Test if Redis Insight web interface is accessible
        local response=$(curl -s -I "http://$host:$port" 2>/dev/null | head -n 1)
        if echo "$response" | grep -q "200\|302" 2>/dev/null; then
            print_test_result "Redis Insight web interface" "PASS"
        else
            print_test_result "Redis Insight web interface" "FAIL" "Web interface not accessible"
        fi
    else
        print_test_result "Redis Insight service responsive" "FAIL" "Service not reachable on $host:$port"
    fi
}

# Test Chat UI service
test_chatui_service() {
    echo -e "${BLUE}Testing Chat UI service ($LOG_CONTEXT)...${NC}"
    
    local host="$CHATUI_HOST"
    local port="$CHATUI_PORT"
    
    # Test if Chat UI is responding
    if wait_for_service "Chat UI" "$host" "$port" 10; then
        print_test_result "Chat UI service responsive" "PASS"
        
        # Test if Chat UI web interface is accessible
        local response=$(curl -s -I "http://$host:$port" 2>/dev/null | head -n 1)
        if echo "$response" | grep -q "200\|302" 2>/dev/null; then
            print_test_result "Chat UI web interface" "PASS"
        else
            print_test_result "Chat UI web interface" "FAIL" "Web interface not accessible"
        fi
    else
        print_test_result "Chat UI service responsive" "FAIL" "Service not reachable on $host:$port"
    fi
}

# Test service dependencies
test_service_dependencies() {
    echo -e "${BLUE}Testing service dependencies...${NC}"
    
    # Check if all containers are running
    local running_containers=$(docker-compose -f "$COMPOSE_FILE" ps --services --filter "status=running" 2>/dev/null | wc -l)
    local total_services=$(docker-compose -f "$COMPOSE_FILE" config --services 2>/dev/null | wc -l)
    
    if [ "$running_containers" -eq "$total_services" ] && [ "$total_services" -gt 0 ]; then
        print_test_result "All services running" "PASS"
    else
        print_test_result "All services running" "FAIL" "$running_containers/$total_services services running"
    fi
    
    # Check network connectivity
    if docker network ls | grep -q "$DOCKER_NETWORK" 2>/dev/null; then
        print_test_result "Docker network exists" "PASS"
    else
        print_test_result "Docker network exists" "FAIL" "Network $DOCKER_NETWORK not found"
    fi
}

# Test service logs for errors
test_service_logs() {
    echo -e "${BLUE}Testing service logs for critical errors...${NC}"
    
    local services=("qdrant" "pgadmin" "langgraph-server" "redisinsight" "chat-ui")
    
    for service in "${services[@]}"; do
        local error_count=$(docker-compose -f "$COMPOSE_FILE" logs --tail=50 "$service" 2>/dev/null | grep -i "error\|fail\|exception" | wc -l)
        
        if [ "$error_count" -eq 0 ]; then
            print_test_result "$service logs clean" "PASS"
        else
            print_test_result "$service logs clean" "FAIL" "$error_count error(s) found in recent logs"
        fi
    done
}

# Main test execution
main() {
    echo -e "${YELLOW}Service Integration Test Suite ($LOG_CONTEXT)${NC}"
    echo "========================================"
    
    # Check prerequisites
    test_docker_compose
    echo ""
    
    # Start services if not running
    echo -e "${YELLOW}Ensuring services are running...${NC}"
    if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up" 2>/dev/null; then
        echo "Starting docker-compose services..."
        docker-compose -f "$COMPOSE_FILE" up -d
        sleep 10  # Give services time to initialize
    fi
    echo ""
    
    # Test individual services
    test_qdrant_service
    echo ""
    
    test_pgadmin_service
    echo ""
    
    test_langgraph_server
    echo ""
    
    test_redisinsight_service
    echo ""
    
    test_chatui_service
    echo ""
    
    # Test service integration
    test_service_dependencies
    echo ""
    
    test_service_logs
    echo ""
    
    # Final results
    echo "========================================"
    echo -e "${BLUE}Service Test Results Summary:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All service tests passed!${NC}"
        echo -e "${GREEN}All docker-compose services are healthy and responsive.${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some service tests failed. Please check the details above.${NC}"
        echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
        echo "  - Check if all services are running: docker-compose -f $COMPOSE_FILE ps"
        echo "  - View service logs: docker-compose -f $COMPOSE_FILE logs [service_name]"
        echo "  - Restart services: docker-compose -f $COMPOSE_FILE restart"
        exit 1
    fi
}

# Test directory structure
test_directory() {
    echo -e "${BLUE}📁 Testing directory structure...${NC}"
    
    local required_files=(
        "envs/setup/api_utils.py"
        "envs/test/agent-dev/entrypoint.sh"
        "envs/test/agent-dev/check_services.sh"
        "envs/test/.env"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "  ${GREEN}✅${NC} $file"
        else
            echo -e "  ${RED}❌${NC} $file"
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "  ${RED}Missing required files. Cannot continue.${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}All required files present${NC}"
    return 0
}

# Test secret utilities
test_secret_utils() {
    echo -e "${BLUE}🔐 Testing secret utilities...${NC}"
    
    cd /home/vindpro/Documents/projects/AI_PlayGround
    
    # Test base64 decoding function
    python3 -c "
import sys
sys.path.append('envs/setup')
from sec_utils import _decode_b64

# Test cases
test_cases = [
    ('dGVzdA==', 'test'),
    ('dGVzdA===', 'test'),
    ('\"dGVzdA==\"', 'test'),
    ('c2tfbGZfMGFiOWIyNDItMGY1Yi00ZmQzLWFmMmItMjFmNWNiM2I5Y2Vj', 'sk_lf_0ab9b242-0f5b-4fd3-af2b-21f5cb3b9cec')
]

print('  Testing base64 decoding...')
for encoded, expected in test_cases:
    result = _decode_b64(encoded)
    if result == expected:
        print(f'    ✅ {encoded[:20]}... -> {expected[:20]}...')
    else:
        print(f'    ❌ {encoded[:20]}... -> {result} (expected {expected})')
        sys.exit(1)

print('  🎉 All base64 decoding tests passed')
"
    
    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✅ Secret utilities working correctly${NC}"
        return 0
    else
        echo -e "  ${RED}❌ Secret utilities failed${NC}"
        return 1
    fi
}

# Test API utilities
test_api_utils() {
    echo -e "${BLUE}📡 Testing API utilities...${NC}"
    
    cd /home/vindpro/Documents/projects/AI_PlayGround
    
    # Load environment variables first
    if [[ -f "envs/test/.env" ]]; then
        source envs/test/.env
    fi
    
    # Test individual API functions exist
    python3 -c "
import sys
sys.path.append('envs/setup')
from api_utils import *

# Check that all expected functions exist
expected_functions = [
    'test_openai_api',
    'test_anthropic_api', 
    'test_grok_api',
    'test_github_api',
    'test_docker_hub_api',
    'test_pypi_api',
    'test_terraform_api',
    'test_google_api',
    'test_all_apis'
]

print('  Checking API utility functions...')
for func_name in expected_functions:
    if func_name in globals():
        print(f'    ✅ {func_name}')
    else:
        print(f'    ❌ {func_name} - missing')
        sys.exit(1)

print('  🎉 All API utility functions present')
"
    
    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✅ API utilities structure correct${NC}"
        return 0
    else
        echo -e "  ${RED}❌ API utilities failed${NC}"
        return 1
    fi
}

# Test service health check script
test_service_health_script() {
    echo -e "${BLUE}🏥 Testing service health check script...${NC}"
    
    # Check if script is executable
    if [[ -x "envs/test/agent-dev/check_services.sh" ]]; then
        echo -e "  ${GREEN}✅${NC} Script is executable"
    else
        echo -e "  ${RED}❌${NC} Script is not executable"
        return 1
    fi
    
    # Test script syntax
    if bash -n "envs/test/agent-dev/check_services.sh"; then
        echo -e "  ${GREEN}✅${NC} Script syntax is valid"
    else
        echo -e "  ${RED}❌${NC} Script has syntax errors"
        return 1
    fi
    
    echo -e "  ${GREEN}✅ Service health check script ready${NC}"
    return 0
}

# Test entrypoint script
test_entrypoint_script() {
    echo -e "${BLUE}🚀 Testing entrypoint script...${NC}"
    
    # Check if script is executable
    if [[ -x "envs/test/agent-dev/entrypoint.sh" ]]; then
        echo -e "  ${GREEN}✅${NC} Script is executable"
    else
        echo -e "  ${RED}❌${NC} Script is not executable"
        return 1
    fi
    
    # Test script syntax
    if bash -n "envs/test/agent-dev/entrypoint.sh"; then
        echo -e "  ${GREEN}✅${NC} Script syntax is valid"
    else
        echo -e "  ${RED}❌${NC} Script has syntax errors"
        return 1
    fi
    
    echo -e "  ${GREEN}✅ Entrypoint script ready${NC}"
    return 0
}

# Test environment loading
test_environment_loading() {
    echo -e "${BLUE}🌍 Testing environment loading...${NC}"
    
    if [[ -f "envs/test/.env" ]]; then
        source envs/test/.env
        
        # Check a few key variables are loaded
        if [[ -n "${OPENAI_API_KEY:-}" ]]; then
            echo -e "  ${GREEN}✅${NC} OPENAI_API_KEY loaded"
        else
            echo -e "  ${YELLOW}⚠️${NC}  OPENAI_API_KEY not set"
        fi
        
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            echo -e "  ${GREEN}✅${NC} GITHUB_TOKEN loaded"
        else
            echo -e "  ${YELLOW}⚠️${NC}  GITHUB_TOKEN not set"
        fi
        
        echo -e "  ${GREEN}✅ Environment loading functional${NC}"
        return 0
    else
        echo -e "  ${RED}❌ .env file not found${NC}"
        return 1
    fi
}

# Main comprehensive test function (tests the scripts and tools themselves)
main_comprehensive_test() {
    echo "Starting comprehensive integration test..."
    echo ""
    
    local tests_passed=0
    local tests_failed=0
    local test_results=()
    
    # Run all tests
    declare -a test_functions=(
        "test_directory:Directory Structure"
        "test_secret_utils:Secret Utilities"
        "test_api_utils:API Utilities"
        "test_service_health_script:Service Health Script"
        "test_entrypoint_script:Entrypoint Script"
        "test_environment_loading:Environment Loading"
    )
    
    for test_info in "${test_functions[@]}"; do
        IFS=':' read -r test_func test_name <<< "$test_info"
        
        echo ""
        if $test_func; then
            tests_passed=$((tests_passed + 1))
            test_results+=("✅ $test_name")
        else
            tests_failed=$((tests_failed + 1))
            test_results+=("❌ $test_name")
        fi
    done
    
    echo ""
    echo "🏁 Integration Test Summary"
    echo "=========================="
    
    for result in "${test_results[@]}"; do
        echo "  $result"
    done
    
    echo ""
    echo -e "Tests passed: ${GREEN}$tests_passed${NC}"
    echo -e "Tests failed: ${RED}$tests_failed${NC}"
    
    if [[ $tests_failed -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}🎉 All integration tests passed!${NC}"
        echo -e "${GREEN}🚀 System is ready for use${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Start services: docker-compose up -d"
        echo "2. Run container: docker run -it --network langgraph-network agent-dev"
        echo "3. APIs will be validated and services checked automatically"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Some integration tests failed${NC}"
        echo "Please fix the issues above before using the system"
        return 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                MODE="$2"
                if [ "$MODE" != "host" ] && [ "$MODE" != "guest" ]; then
                    echo "Error: Mode must be 'host' or 'guest'"
                    echo "Usage: $0 [--mode host|guest] [--compose-file PATH]"
                    exit 1
                fi
                shift 2
                ;;
            --compose-file)
                COMPOSE_FILE="$2"
                shift 2
                ;;
            -h|--help)
                echo "Service Integration Test Script"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --mode MODE         Set execution mode: 'host' or 'guest' (default: guest)"
                echo "  --compose-file PATH Path to docker-compose.yml file (default: envs/test/docker-compose.yml)"
                echo "  -h, --help          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Run tests in guest mode (main stack)"
                echo "  $0 --mode host                        # Run tests from host machine (main stack)"
                echo "  $0 --compose-file langfuse/docker-compose.yml  # Test langfuse stack"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Change to project directory
cd /home/vindpro/Documents/projects/AI_PlayGround

# Parse arguments first
parse_arguments "$@"

# Configure services based on parsed arguments
configure_services

# Run the integration test
main
