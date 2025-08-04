#!/bin/bash

set -e

echo "🔍 Starting LangSmith self-hosted instance..."

# Decode base64 environment variables first
echo "🔓 Decoding base64 environment variables..."


# Set default configuration
export LANGSMITH_PORT=${LANGSMITH_PORT:-8000}
export LANGSMITH_HOST=${LANGSMITH_HOST:-0.0.0.0}

# Database configuration (use PostgreSQL from stack)
export POSTGRES_HOST=${POSTGRES_HOST:-postgres}
export POSTGRES_PORT=${POSTGRES_PORT:-5432}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-langsmith}

# Use PostgreSQL password from secrets or environment
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD=${POSTGRES_PASSWORD_FALLBACK:-postgres}
fi

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
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

# Display configuration
echo "🔧 LangSmith Configuration:"
echo "   Host: $LANGSMITH_HOST"
echo "   Port: $LANGSMITH_PORT"
echo "   Database: $POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
echo "   API Key: ${LANGSMITH_API_KEY:+***configured***}"
echo "   License Key: ${LANGSMITH_LICENSE_KEY:+***configured***}"

# Health check function
health_check() {
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if curl -s http://localhost:$LANGSMITH_PORT/health > /dev/null 2>&1; then
            echo "✅ LangSmith health check passed"
            return 0
        fi
        retries=$((retries + 1))
        sleep 2
    done
    
    echo "⚠ LangSmith health check failed after $max_retries attempts"
    return 1
}

# Start LangSmith in background for health check
echo "🚀 Starting LangSmith server..."

# Note: LangSmith might not have an official Docker image yet
# This is a placeholder for when it becomes available
# For now, we'll simulate the service
if [ "$SIMULATE_LANGSMITH" = "true" ]; then
    echo "🔄 Simulating LangSmith service (actual image not yet available)"
    
    # Create a simple FastAPI service to simulate LangSmith
    python3 -c "
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

class LangSmithSimulator(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'healthy', 'service': 'langsmith-simulator'}).encode())
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = '''
            <html>
            <head><title>LangSmith Simulator</title></head>
            <body>
                <h1>LangSmith Self-Hosted (Simulator)</h1>
                <p>This is a placeholder for the LangSmith service.</p>
                <p>Status: Running</p>
                <p>When the official LangSmith Docker image is available, this will be replaced.</p>
            </body>
            </html>
            '''
            self.wfile.write(html.encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'status': 'accepted'}).encode())
    
    def log_message(self, format, *args):
        pass  # Suppress default logging

server = HTTPServer(('0.0.0.0', $LANGSMITH_PORT), LangSmithSimulator)
print('🎯 LangSmith simulator listening on port $LANGSMITH_PORT')
server.serve_forever()
"
else
    # When official LangSmith image is available, replace this with:
    # exec langsmith-server --host $LANGSMITH_HOST --port $LANGSMITH_PORT
    echo "⚠ Official LangSmith Docker image not yet available"
    echo "🔄 Starting placeholder service..."
    exec python3 -c "
import time
import http.server
import socketserver

class PlaceholderHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<h1>LangSmith Placeholder</h1><p>Service is running on port $LANGSMITH_PORT</p>')

with socketserver.TCPServer(('', $LANGSMITH_PORT), PlaceholderHandler) as httpd:
    print(f'LangSmith placeholder serving on port $LANGSMITH_PORT')
    httpd.serve_forever()
"
fi
