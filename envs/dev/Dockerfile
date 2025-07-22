# docker/dev/Dockerfile
# 🚨 SECURITY NOTE: This is the DEVELOPMENT container only
# - Uses fake/sample secrets from config/dev_secrets.yaml
# - NOT included in GitHub Actions workflows or security reports
# - Safe for local development and testing
# - Production deployments use .github/actions/r2d/Dockerfile instead

# ─── 1) Base image & tools ─────────────────────────────────────────────────────
FROM ubuntu:22.04

ENV HISTFILE=/home/user/.bash_history \
    HISTCONTROL=ignoreboth \
    HISTSIZE=1000 \
    HISTFILESIZE=2000 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=UTC

RUN apt-get update && apt-get install -y \
      bash \
      software-properties-common \
      curl \
      git \
      wget \
      ca-certificates \
      gnupg \
      lsb-release \
      iputils-ping \
      dnsutils \
      net-tools \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
      python3.12 \
      python3.12-venv \
      python3.12-dev \
    && ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (includes npm and npx)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform

# Install tfsec for security scanning
RUN curl -sSfL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64 -o /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec
# install git cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install -y gh
# ─── 2) Install packaging helpers as root (so pipreqs ends up in /usr/local/bin) ─
RUN python -m pip install --upgrade pip \
 && python -m pip install pipreqs tomlkit build setuptools wheel

# Install main application dependencies
RUN python -m pip install \
    anthropic==0.58.2 \
    google_api_python_client==2.170.0 \
    langchain_anthropic==0.3.17 \
    "langchain-core>=0.3.62,<1.0.0" \
    langchain_google_genai==2.1.8 \
    langchain_openai==0.3.28 \
    langgraph==0.5.3 \
    openai==1.97.0 \
    "protobuf>=5.27.0" \
    pydantic==2.11.7 \
    PyYAML==6.0.2 \
    Requests==2.32.4 \
    typing_extensions==4.14.1 \
    "GitPython>=3.1,<4.0"

# Install google-generativeai separately to avoid dependency conflicts
RUN python -m pip install google-generativeai

# Install development and testing dependencies
RUN python -m pip install \
    pytest>=7.0.0 \
    pytest-mock>=3.10.0 \
    black>=22.0.0 \
    flake8>=4.0.0 \
    isort>=5.0.0 \
    bandit>=1.7.0 \
    ipython>=8.0.0

# ─── 3) Create non‑root user & persistent bash history ─────────────────────────
RUN useradd -m -s /bin/bash user \
 && touch /home/user/.bash_history \
 && chown user:user /home/user/.bash_history \
 && chmod 600 /home/user/.bash_history \
 && echo 'PROMPT_COMMAND="history -a; history -w; $PROMPT_COMMAND"' \
       >> /home/user/.bashrc

# Configure npm for the user account - set up npm to use user directory for global installs
RUN mkdir -p /home/user/.npm-global \
 && chown -R user:user /home/user/.npm-global \
 && echo 'export PATH=/home/user/.npm-global/bin:$PATH' >> /home/user/.bashrc \
 && echo 'export NPM_CONFIG_PREFIX=/home/user/.npm-global' >> /home/user/.bashrc \
 && echo 'export NPM_CONFIG_CACHE=/home/user/.npm-cache' >> /home/user/.bashrc

# Switch to user and configure npm properly
USER user
RUN npm config set prefix '/home/user/.npm-global' \
 && npm config set cache '/home/user/.npm-cache' \
 && mkdir -p /home/user/.npm-cache

# Switch back to root for final setup
USER root

# ─── 4) Entrypoint hooked during docker run by build_local.sh and build local calls updat_deps.py
# Which check requirments.txt and update it if needed and install all the dependencies
#COPY docker/dev/entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh
RUN git config --global --add safe.directory /home/user/app
RUN mkdir -p /workspace && \
    chown -R user:user /workspace && \
    chmod -R 775 /workspace
USER user
WORKDIR /home/user/app