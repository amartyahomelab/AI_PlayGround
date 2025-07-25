# Qdrant Vector Database Container
# 🎯 PURPOSE: Vector database for LangGraph memory and embeddings
# - Simple vector storage without complex secret management needs
# - Extends official Qdrant image with health checks

FROM qdrant/qdrant:latest

# Install curl for health checks
USER root
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy custom entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Stay as root user since we're just adding basic tooling
# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
