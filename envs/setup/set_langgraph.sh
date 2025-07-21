# Clone LangChain
git clone https://github.com/langchain-ai/langchain.git
cd langchain
pip install -e .

# Clone LangGraph
git clone https://github.com/langchain-ai/langgraph.git
cd langgraph
pip install -e .
# Build CLI
pip install langgraph-cli
npx @langchain/langgraph-cli

# Clone LangGraph Studio (Desktop/Web IDE)
git clone https://github.com/langchain-ai/langgraph-studio.git
cd langgraph-studio
npm install  # or yarn
# note: desktop app deprecated—use web frontend

# (Optional) Clone Agent Chat UI
git clone https://github.com/langchain-ai/agent-chat-ui.git
cd agent-chat-ui
pnpm install
