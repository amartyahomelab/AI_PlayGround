#!/bin/sh
set -e

echo "💬 Starting Chat UI for LangGraph..."

# Check if chat app already exists
if [ -d "/app/chat-app" ]; then
    echo "🔄 Removing existing chat app to apply port configuration..."
    rm -rf /app/chat-app
fi

echo "🚀 Creating React chat application..."
cd /app
npx create-react-app chat-app --template typescript
cd chat-app

# Install dependencies
npm install axios

echo "✅ Chat application configured successfully!"

# Start the development server
echo "🚀 Starting development server on port 5173..."
PORT=5173 npm start
