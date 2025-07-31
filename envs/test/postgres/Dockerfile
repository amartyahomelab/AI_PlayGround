# PostgreSQL Container with Secret Management Integration
# 🎯 PURPOSE: Database for LangGraph checkpointing and LangSmith data
# - Integrates with secret management system
# - Sets up multiple databases (postgres, langsmith)
# - Loads PostgreSQL extensions for vector operations

FROM postgres:16-alpine

# Install Python and dependencies for secret management
RUN apk add --no-cache python3 py3-pip py3-yaml curl

# Copy initialization scripts
COPY init/*.sql /docker-entrypoint-initdb.d/

# Copy custom entrypoint with secret management
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use custom entrypoint that integrates secret management and calls original
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
