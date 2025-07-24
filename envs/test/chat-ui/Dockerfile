FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    curl \
    netcat-openbsd

# Set working directory
WORKDIR /app

# Set PORT environment variable
ENV PORT=5173

# Install global packages
RUN npm install -g create-react-app serve

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port
EXPOSE 5173

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
