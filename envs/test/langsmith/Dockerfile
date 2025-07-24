FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set working directory  
WORKDIR /app

# Install basic Python packages for a simple LangSmith simulator
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    pydantic \
    psycopg2-binary

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
