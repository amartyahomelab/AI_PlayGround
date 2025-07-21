# AI_PlayGround

A comprehensive AI development environment with Docker containerization, multi-API support, and automated testing utilities.

## 🚀 Features

- **Containerized Development Environment**: Docker-based setup with Ubuntu 22.04, Python 3.12
- **Multi-API Support**: Integration with OpenAI, Google Gemini, Anthropic Claude, GitHub, and Terraform APIs
- **Secrets Management**: Base64-encoded secrets with automated environment variable export
- **Automated Testing**: Built-in API connectivity testing and validation
- **Development Tools**: Terraform, tfsec, GitHub CLI, and Python development packages
- **Interactive Shell**: Drop into a fully configured development environment

## 🏗️ Architecture

```
AI_PlayGround/
├── envs/
│   ├── dev/
│   │   ├── Dockerfile          # Container definition
│   │   ├── entrypoint.sh       # Container initialization
│   │   └── docker-compose.yml  # Docker Compose configuration
│   └── setup/
│       ├── build_local.sh      # Build and run script
│       ├── export_env.py       # Environment variable export
│       ├── sec_utils.py        # Secrets management
│       └── api_utils.py        # API testing utilities
└── diagram-to-iac/             # Main project (if applicable)
```

## 🛠️ Prerequisites

- Docker Desktop
- Python 3.12+
- Git

## ⚡ Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/amartyahomelab/AI_PlayGround.git
   cd AI_PlayGround
   ```

2. **Configure secrets** (optional for basic usage):
   ```bash
   cp envs/config/secrets_example.yaml envs/config/secrets.yaml
   # Edit the secrets.yaml file with your API keys (base64 encoded)
   ```

3. **Build and run the development environment**:
   ```bash
   ./envs/setup/build_local.sh
   ```

4. **Start developing**! You'll be dropped into an interactive bash shell with all APIs configured.

## 🔐 Secrets Management

The environment supports base64-encoded secrets stored in `envs/config/secrets.yaml`. The system will:

1. Load secrets from the YAML file
2. Decode base64-encoded values
3. Export them as environment variables
4. Test API connectivity automatically

### Supported APIs

- **OpenAI**: GPT models and embeddings
- **Google Gemini**: Generative AI capabilities
- **Anthropic Claude**: Advanced reasoning and analysis
- **GitHub**: Repository and workflow management
- **Terraform**: Infrastructure as Code operations

## 🧪 Testing

The environment includes automated API testing:

```bash
# API tests run automatically on container startup
# Manual testing can be done with:
python3 envs/setup/api_utils.py
```

## 🔧 Development

### Container Build Process

1. **Base Image**: Ubuntu 22.04 with Python 3.12
2. **Tools Installation**: Terraform, tfsec, GitHub CLI
3. **Python Packages**: AI/ML libraries, testing frameworks
4. **User Setup**: Non-root user with proper permissions
5. **Environment Export**: Automated secrets loading

### Key Scripts

- `build_local.sh`: Main build and run script
- `export_env.py`: Environment variable bridge between Python and shell
- `sec_utils.py`: Secrets loading and validation
- `api_utils.py`: API connectivity testing
- `entrypoint.sh`: Container initialization

## 📝 Configuration

### Environment Variables

The following environment variables are automatically loaded if configured:

```bash
OPENAI_API_KEY          # OpenAI API access
GOOGLE_API_KEY          # Google Gemini API access
ANTHROPIC_API_KEY       # Anthropic Claude API access
GITHUB_TOKEN            # GitHub API access
TFE_TOKEN              # Terraform Cloud/Enterprise
DOCKERHUB_API_KEY       # Docker Hub access
DOCKERHUB_USERNAME      # Docker Hub username
PYPI_API_KEY           # Python Package Index
GROK_API_KEY           # Grok API (if applicable)
```

### Docker Configuration

- **Image Name**: `ai-dev`
- **Container Name**: `ai-dev-container`
- **Working Directory**: `/home/user/app`
- **Volume Mounts**: Project directory and bash history
- **Network**: Host networking for API access

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in the containerized environment
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🆘 Troubleshooting

### Common Issues

**Container build fails with dependency conflicts**:
- Check the Dockerfile for package version conflicts
- Ensure Python requirements are compatible

**Environment variables not loading**:
- Verify secrets.yaml format and base64 encoding
- Check file permissions and paths

**API tests failing**:
- Confirm API keys are valid and have proper permissions
- Check network connectivity from container

### Debug Mode

Run with debug output:
```bash
DEBUG=1 ./envs/setup/build_local.sh
```

## 🔗 Links

- [GitHub Repository](https://github.com/amartyahomelab/AI_PlayGround)
- [Docker Hub](https://hub.docker.com/) (if published)
- [Documentation](docs/) (if available)

---

**Built with ❤️ for AI Development**
