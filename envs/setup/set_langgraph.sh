# Clone LangChain
git clone https://github.com/langchain-ai/langchain.git
cd langchain
pip install -e .

# Clone LangGraph
git clone https://github.com/langchain-ai/langgraph.git
cd langgraph
pip install -e .
# Build CLI - Install the CLI directly without updating npm
npm install -g @langchain/langgraph-cli

# Clone LangGraph Studio (Desktop/Web IDE)
git clone https://github.com/langchain-ai/langgraph-studio.git
cd langgraph-studio
npm install  # or yarn
# note: desktop app deprecated—use web frontend

# (Optional) Clone Agent Chat UI
git clone https://github.com/langchain-ai/agent-chat-ui.git
cd agent-chat-ui
# Install pnpm if needed and use it
npm install -g pnpm
pnpm install
