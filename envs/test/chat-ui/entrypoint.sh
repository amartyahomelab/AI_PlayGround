#!/bin/sh
set -ex

echo "💬 Starting Chat UI for LangGraph..."

ls -l /app
ls -l /app/agent-chat-ui || true

cd /app/agent-chat-ui

# Install dependencies with pnpm only (fail if not present)
pnpm install

# Show environment and Next.js version
printenv
npx next --version || true

# Start the Next.js dev server
exec pnpm dev
