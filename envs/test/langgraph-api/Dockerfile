# LangGraph API Container with Secret Management
# 🎯 PURPOSE: Official LangGraph API server + bundled Studio UI
# - Uses official langchain/langgraph-api image
# - Integrates with secret management system
# - Connects to PostgreSQL, Qdrant, and LangSmith
# - Serves both API and Studio UI on port 2024

FROM langchain/langgraph-api:0.2.100-py3.13-wolfi

# Install additional system dependencies for secret management
RUN apk update && apk add --no-cache \
    curl \
    netcat-openbsd

# Copy custom entrypoint with secret management
COPY entrypoint.sh /app/langgraph-api/entrypoint.sh
RUN chmod +x /app/langgraph-api/entrypoint.sh

# Expose port
EXPOSE 2024

# Set custom entrypoint
ENTRYPOINT ["/app/langgraph-api/entrypoint.sh"]
