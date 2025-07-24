# LangChain + LangGraph Ecosystem Guide

The LangChain + LangGraph ecosystem provides **five visible pillars** (LangChain core, LangGraph runtime, LangGraph Studio, Agent Chat UI, LangSmith), but the ecosystem is deeper: there are tooling, runtime, and cloud pieces that round out a full-stack, enterprise-ready platform.

## 🧩 Runtime & Dev-Ops Add-ons

| Component | What it does | Why it matters |
|-----------|--------------|----------------|
| **LangGraph CLI** | Scaffolds new graphs, hot-reload dev server, builds Docker images, pushes to registries. Sources: [LangChain AI](https://langchain-ai.github.io/langgraph/), [PyPI](https://pypi.org/project/langgraph-cli/) | One-command local dev & GitOps pipelines. |
| **LangGraph Server** | Production API (FastAPI) that runs graphs with built-in persistence, task queues, auth, and rate-limits. Source: [LangChain AI](https://langchain-ai.github.io/langgraph/) | Deploy as a micro-service or on K8s; same API in local & cloud. |
| **Checkpointer library** | Pluggable SQLite, Postgres, S3, Redis checkpoint stores for durable state + time-travel. Sources: [LangChain AI](https://langchain-ai.github.io/langgraph/), [LangChain Blog](https://blog.langchain.dev/) | Enables crash-recovery, audit, human-in-the-loop. |

## 🖥️ Front-end / Demo Helpers

| Component | Purpose | Notes |
|-----------|---------|-------|
| **LangGraph JS Studio Starter** | Vite/React starter with package.json for hacking the Studio front-end. | Point it at any LangGraph Server for live graphs. |
| **Agent Chat UI** | Opinionated React chat app that streams tool calls & thoughts. | Drop-in demo for stakeholders. |

## 🧪 Observability & Eval Layer

- **LangSmith Eval SDK & UI** – run automatic regressions, GPT-judge evals, and dataset-driven tests against any LangGraph app.
  - Sources: [LangSmith](https://smith.langchain.com/), [LangSmith SDK](https://github.com/langchain-ai/langsmith-sdk), [LangChain](https://github.com/langchain-ai/langchain)

- **OpenTelemetry export** built into LangGraph Server for vendor-agnostic metrics.
  - Source: [LangChain AI](https://langchain-ai.github.io/langgraph/)

## 🛠️ Content & Template Re-use

| Asset Hub | What's inside | Why care |
|-----------|---------------|----------|
| **LangChain Hub** | Versioned prompts, chains, and agent blueprints. Source: [LangSmith](https://smith.langchain.com/hub) | Re-use certified building blocks across projects. |
| **LangChain Templates** | End-to-end reference apps (RAG, chat-bots) with infra IaC. Source: [Langchain Templates](https://github.com/langchain-ai/langchain/tree/master/templates) | Kick-start PoCs without re-inventing boilerplate. |

## 🌩️ Cloud & Managed Options

- **LangGraph Platform (Cloud/Hybrid)** – hosted server, Studio, and auto-scaling runners; connect repos for CI/CD.
  - 📦 [LangChain](https://langchain.com/)

- **Local-server tutorial** shows a fully Dockerized, self-host stack (Server + Studio) in under 60 seconds.
  - 📦 [LangChain AI](https://langchain-ai.github.io/langgraph/)

## 🚀 Quick Start

This repository includes a setup script (`set_langgraph.sh`) that installs the core components:

```bash
# Run the setup script
./envs/setup/set_langgraph.sh
```

The script will:

1. Clone and install LangChain from source
2. Clone and install LangGraph from source  
3. Install LangGraph CLI globally
4. Clone LangGraph Studio (deprecated desktop app)
5. Clone Agent Chat UI with pnpm support

## 📋 Development Workflow

### Modern LangGraph Development (Recommended)

```bash
# Use the CLI for new projects
langgraph new my-project
cd my-project
langgraph dev  # Hot-reload development server
langgraph up   # Production server
```

### Legacy Studio (Desktop App - Deprecated)

The `langgraph-studio` directory contains files from the deprecated desktop application. Use the CLI approach above for current development.

### Agent Chat UI Development

```bash
cd agent-chat-ui
pnpm install
pnpm dev
```

## 🔗 Key Links

- **Main Documentation**: [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- **LangSmith Platform**: [smith.langchain.com](https://smith.langchain.com/)
- **Community**: [LangChain Discord](https://discord.gg/langchain)
- **Templates & Examples**: [LangChain Templates](https://github.com/langchain-ai/langchain/tree/master/templates)

---

**Last updated:** July 22, 2025
