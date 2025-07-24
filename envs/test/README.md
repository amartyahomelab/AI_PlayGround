# Self-Hosted LangGraph Stack

This directory contains a complete self-hosted LangGraph development stack using Docker Compose. It provides all the runtime services needed for LangGraph development without any SaaS dependencies.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 8GB RAM available
- Ports 5432, 6333, 6379, 8000, 2024, and 5173 available

### Easy Startup (Recommended)

Use the provided startup script for the best experience:

```bash
cd envs/test

# Start everything with health checks and status
./start.sh start

# Check service status and get URLs
./start.sh status

# Start development container
./start.sh dev

# View logs
./start.sh logs

# Stop everything
./start.sh stop
```

### Manual Startup

If you prefer manual control:

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings (optional - secrets managed automatically)
   ```

2. **Start services:**
   ```bash
   docker-compose up -d --build
   ```

3. **Verify deployment:**
   - 🎯 LangGraph API + Studio: http://localhost:2024
   - 💬 Chat UI Demo: http://localhost:5173
   - 🔍 Qdrant Dashboard: http://localhost:6333/dashboard
   - 📈 LangSmith UI: http://localhost:8000
   - 🐘 PostgreSQL: localhost:5432

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    LangGraph Self-Hosted Stack                 │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Layer                                                │
│  ┌─────────────────┐  ┌─────────────────────────────────────┐   │
│  │   Chat UI       │  │      LangGraph Studio              │   │
│  │   (React App)   │  │   (bundled in langgraph-server)    │   │
│  │   Port: 5173    │  │      Port: 2024                    │   │
│  └─────────────────┘  └─────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  API Layer                                                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              LangGraph Server                              │ │
│  │        (FastAPI + Studio UI Bundle)                       │ │
│  │              Port: 2024                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Observability Layer                                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    LangSmith                              │ │
│  │        (Self-hosted tracing & evaluation)                 │ │
│  │                  Port: 8000                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer                                                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────────┐ │
│  │ PostgreSQL  │ │    Redis    │ │          Qdrant             │ │
│  │(Checkpoints)│ │ (Caching)   │ │    (Vector Search)          │ │
│  │ Port: 5432  │ │ Port: 6379  │ │   Ports: 6333, 6334        │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Stack Components

### Runtime Services (via Docker Compose)
- **LangGraph Server** (`langchain/langgraph-api:latest`) - Production API + bundled Studio UI
- **PostgreSQL** (`postgres:16-alpine`) - Durable state & checkpointing with time-travel
- **Redis** (`redis:7-alpine`) - LangSmith caching layer
- **Qdrant** (`qdrant/qdrant:v1.9`) - Vector database for memory and RAG
- **LangSmith** (`ghcr.io/langchain-ai/langsmith:latest`) - Self-hosted tracing & evaluation
- **Agent Chat UI** (`ghcr.io/langchain-ai/agent-chat-ui:latest`) - Demo interface

### Development Container (Separate)
- **Agent Dev** - Your development environment with LangGraph CLI, SDKs, and all tooling

## 🔐 Secret Management Integration

All containers integrate with your existing secret management system:

1. **Base64-encoded secrets** in `envs/config/secrets.yaml`
2. **Secret loader** (`envs/setup/sec_utils.py`) in each container
3. **Mount pattern**: `/run/secrets.yaml` in all containers
4. **Environment injection**: Entrypoint scripts decode and export API keys

Required secrets:
```yaml
# envs/config/secrets.yaml
OPENAI_API_KEY: <base64-encoded>
ANTHROPIC_API_KEY: <base64-encoded>
GOOGLE_API_KEY: <base64-encoded>
GITHUB_TOKEN: <base64-encoded>
POSTGRES_PASSWORD: <base64-encoded>
```

## 🛠️ Development Plan

### Phase 1: Infrastructure Services
- [x] Create directory structure under `envs/test/`
- [ ] PostgreSQL setup with init scripts
- [ ] Qdrant vector store configuration
- [ ] LangSmith self-hosted setup
- [ ] Network and volume configuration

### Phase 2: LangGraph Services
- [ ] LangGraph API server configuration
- [ ] Studio UI access setup
- [ ] Environment variable management
- [ ] Service dependencies and health checks

### Phase 3: Development Environment
- [ ] Agent dev container (based on `envs/dev/Dockerfile`)
- [ ] CLI tools installation (langgraph-cli, langsmith, etc.)
- [ ] Volume mounts for live development
- [ ] Entrypoint scripts for each service

### Phase 4: Demo & Testing
- [ ] Agent Chat UI setup
- [ ] Integration testing
- [ ] Documentation and examples
- [ ] Startup scripts and utilities

## 📁 Directory Structure

```
envs/test/
├── README.md                    # This file
├── docker-compose.yml           # Main orchestration
├── .env.example                 # Environment template
├── .env                         # Local environment (gitignored)
├── postgres/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── init/
│       └── 01-init-databases.sql
├── qdrant/
│   ├── Dockerfile
│   └── entrypoint.sh
├── langsmith/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── config/
├── langgraph-server/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── config/
├── agent-dev/
│   ├── Dockerfile               # Based on envs/dev/Dockerfile
│   ├── entrypoint.sh
│   └── workspace/               # Mounted development workspace
└── chat-ui/
    ├── Dockerfile
    └── entrypoint.sh
```

## 🚀 Quick Start

1. **Clone and setup:**
   ```bash
   cd envs/test
   cp .env.example .env
   # Edit .env with your preferences
   ```

2. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

3. **Access services:**
   - LangGraph Studio: http://localhost:2024
   - LangSmith UI: http://localhost:8000
   - Chat Demo UI: http://localhost:5173
   - Qdrant UI: http://localhost:6333/dashboard
   - PostgreSQL: localhost:5432

4. **Development shell:**
   ```bash
   docker-compose exec agent-dev bash
   ```

## 🔧 Configuration

### Environment Variables
- `POSTGRES_PASSWORD` - Database password
- `LANGSMITH_API_KEY` - Self-hosted instance key
- `OPENAI_API_KEY` - For LLM calls (or other provider keys)
- `ANTHROPIC_API_KEY` - Alternative LLM provider
- `GOOGLE_API_KEY` - Google/Gemini API access

### Volumes
- `postgres_data` - Database persistence
- `qdrant_data` - Vector store persistence
- `langsmith_data` - Tracing data persistence
- `./agent-dev/workspace` - Live development code

## 📝 Development Workflow

1. **Start services:** `docker-compose up -d`
2. **Enter dev container:** `docker-compose exec agent-dev bash`
3. **Create new graph:** `langgraph new my-agent`
4. **Develop with hot-reload:** `langgraph dev`
5. **Test via Chat UI:** Open http://localhost:5173
6. **Monitor in LangSmith:** Open http://localhost:8000

## 🔍 Service Details

### LangGraph Server (Port 2024)
- Serves both API and Studio UI
- Connected to PostgreSQL for checkpointing
- Connected to Qdrant for vector operations
- Integrated with LangSmith for tracing

### PostgreSQL (Port 5432)
- Handles durable state for LangGraph checkpointing
- Also provides database for LangSmith
- Automatic initialization scripts
- Volume-backed persistence

### Qdrant (Port 6333)
- Vector database for embeddings and semantic search
- Web UI for debugging vector operations
- Volume-backed persistence
- REST and gRPC APIs available

### LangSmith (Port 8000)
- Self-hosted tracing and evaluation
- Connected to PostgreSQL for data storage
- Web UI for monitoring agent runs
- Evaluation dataset management

### Agent Dev Container
- Based on existing `envs/dev/Dockerfile`
- Pre-installed: LangGraph CLI, LangChain, LangSmith SDK
- Volume-mounted workspace for live development
- All API keys and environment variables available

### Chat UI (Port 5173)
- Demo interface for testing your agents
- Connects to LangGraph Server API
- Shows streaming responses and tool calls
- Pre-configured for local development

## 🛡️ Security Notes

- All services run in isolated Docker network
- Database passwords managed via environment variables
- API keys injected securely into dev container
- No external SaaS dependencies (except LLM providers)

## 📚 Next Steps

After setup:
1. Follow the LangGraph tutorials in the dev container
2. Use the Chat UI to test your first agent
3. Monitor execution traces in LangSmith
4. Experiment with vector operations in Qdrant
5. Scale individual services as needed

---

**Status:** 🚧 Under Development
**Last Updated:** July 23, 2025
