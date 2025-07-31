FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    curl \
    netcat-openbsd

# Install pnpm globally
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy agent-chat-ui source from symlinked directory
COPY agent-chat-ui /app/agent-chat-ui

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Next.js default port
EXPOSE 3000

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
