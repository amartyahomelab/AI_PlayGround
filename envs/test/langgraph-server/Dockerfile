# LangGraph Server Container with Secret Management
# 🎯 PURPOSE: LangGraph dev server with Studio UI
# - Uses slim Python 3.12 Alpine image
# - Installs LangGraph CLI and dependencies
# - Integrates with secret management system
# - Connects to PostgreSQL, Qdrant, and LangSmith
# - Serves both API and Studio UI on port 2024

FROM python:3.12-alpine

# Install system dependencies
RUN apk update && apk add --no-cache \
    curl \
    netcat-openbsd \
    git \
    build-base \
    postgresql-dev \
    bash \
    && rm -rf /var/cache/apk/*

# Install LangGraph and related packages
RUN pip install --no-cache-dir \
    "langgraph-cli[inmem]" \
    langgraph \
    langchain \
    langchain-community \
    psycopg2-binary \
    redis \
    PyYAML \
    && pip cache purge

# Create app directory and user
RUN adduser -D -s /bin/sh langraph
WORKDIR /app
RUN chown langraph:langraph /app

# Switch to non-root user
USER langraph

# Copy custom entrypoint and graphs directory (as root for proper permissions)
USER root
COPY entrypoint.sh /app/entrypoint.sh
COPY graphs/ /app/graphs/
RUN chmod +x /app/entrypoint.sh && chown -R langraph:langraph /app/

# Switch back to non-root user
USER langraph

# Expose port
EXPOSE 2024

# Set custom entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
