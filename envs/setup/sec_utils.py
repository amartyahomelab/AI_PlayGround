# src/diagram_to_iac/tools/sec_utils.py

"""
Load and decode secrets from environment variables or secrets.yaml file.

For GitHub Actions (.github/actions/r2d/Dockerfile):
- Secrets are expected to be provided as base64-encoded environment variables
- Will halt execution if required secrets are missing or empty

For dev containers (docker/dev/Dockerfile):  
- First tries to load from environment variables
- Falls back to /run/secrets.yaml file if env vars not present
- All values (env and file) are expected to be base64 encoded

Mount secrets.yaml into dev container with:
  docker run … -v "$PWD/config/secrets.yaml":/run/secrets.yaml:ro …
"""

import os
import sys
import base64
import pathlib
import binascii

# Import yaml with fallback
try:
    import yaml
except ImportError:
    yaml = None

# Import typing with fallback
try:
    from typing import Dict, List, Optional
except ImportError:
    pass

# Path inside container where the encoded YAML is mounted (dev only)
_YAML_PATH = pathlib.Path("/run/secrets.yaml")

# Expected secrets based on secrets_example.yaml
EXPECTED_SECRETS = [
    "DOCKERHUB_API_KEY",
    "DOCKERHUB_USERNAME", 
    "TF_API_KEY",
    "PYPI_API_KEY",
    "OPENAI_API_KEY",
    "GOOGLE_API_KEY",
    "ANTHROPIC_API_KEY", 
    "GROK_API_KEY",
    "REPO_API_KEY"
]

# Required secrets that must be present (others are optional)
REQUIRED_SECRETS = [
    "REPO_API_KEY"  # GITHUB_TOKEN is required for repo operations
]

# Optional AI API secrets (at least one should be present for AI functionality)
AI_API_SECRETS = [
    "OPENAI_API_KEY",
    "GOOGLE_API_KEY", 
    "ANTHROPIC_API_KEY",
    "GROK_API_KEY"
]

# Map internal secret names to environment variable names
SECRET_ENV_MAPPING = {
    "REPO_API_KEY": "GITHUB_TOKEN",
    "TF_API_KEY": "TFE_TOKEN",
    "DOCKERHUB_API_KEY": "DOCKERHUB_API_KEY",
    "DOCKERHUB_USERNAME": "DOCKERHUB_USERNAME",
    "PYPI_API_KEY": "PYPI_API_KEY", 
    "OPENAI_API_KEY": "OPENAI_API_KEY",
    "GOOGLE_API_KEY": "GOOGLE_API_KEY",
    "ANTHROPIC_API_KEY": "ANTHROPIC_API_KEY",
    "GROK_API_KEY": "GROK_API_KEY"
}

# Alternative environment variable names to check for TFE_TOKEN
TFE_TOKEN_ALTERNATIVES = ["TFE_TOKEN", "TF_TOKEN_app_terraform_io"]


def _decode_b64(enc: str) -> str:
    """Robust Base64 decode: fixes padding, falls back if invalid."""
    enc = enc.strip()
    if not enc:
        return ""
    
    # Fix missing padding - add only the minimum required
    padding_needed = 4 - (len(enc) % 4)
    if padding_needed != 4:  # 4 means no padding needed
        enc += "=" * padding_needed
    
    try:
        decoded = base64.b64decode(enc).decode("utf-8").strip()
        # Strip any base64 padding artifacts that might cause token corruption
        decoded = decoded.rstrip('=')
        return decoded
    except (binascii.Error, UnicodeDecodeError):
        # If it isn't valid Base64, return the raw string
        return enc


def _is_dev_environment() -> bool:
    """Check if running in dev environment by looking for dev-specific indicators."""
    return (
        _YAML_PATH.exists() or 
        os.environ.get("ENVIRONMENT") == "dev" or
        os.path.exists("/workspace/docker/dev")
    )


def _get_env_secrets() -> Dict[str, Optional[str]]:
    """Get secrets from environment variables."""
    env_secrets = {}
    for secret_key in EXPECTED_SECRETS:
        env_name = SECRET_ENV_MAPPING.get(secret_key, secret_key)
        raw_value = os.environ.get(env_name)
        
        # Special handling for TFE_TOKEN - check alternative names
        if secret_key == "TF_API_KEY" and not raw_value:
            for alt_name in TFE_TOKEN_ALTERNATIVES:
                raw_value = os.environ.get(alt_name)
                if raw_value:
                    env_name = alt_name  # Update env_name to the one that worked
                    break
        
        if raw_value:
            # Check if value is already decoded, use as-is; otherwise decode it
            if (secret_key == "TF_API_KEY" and ".atlasv1." in raw_value) or \
               (secret_key == "REPO_API_KEY" and raw_value.startswith("ghp_")) or \
               (secret_key == "OPENAI_API_KEY" and raw_value.startswith("sk-")) or \
               (secret_key == "ANTHROPIC_API_KEY" and raw_value.startswith("sk-ant-")) or \
               (secret_key == "GOOGLE_API_KEY" and not "=" in raw_value and len(raw_value) < 100) or \
               (secret_key in ["DOCKERHUB_USERNAME"] and not "=" in raw_value):
                env_secrets[secret_key] = raw_value
            else:
                env_secrets[secret_key] = _decode_b64(raw_value)
        else:
            env_secrets[secret_key] = None
    return env_secrets


def _load_secrets_from_file() -> Dict[str, str]:
    """Load secrets from secrets.yaml file (dev environment only)."""
    if not _YAML_PATH.exists():
        return {}
    
    try:
        data: Dict[str, str] = yaml.safe_load(_YAML_PATH.read_text()) or {}
        return {k: v for k, v in data.items() if v}
    except Exception as e:
        print(f"❌ Error reading secrets file {_YAML_PATH}: {e}")
        return {}


def _validate_and_set_secrets(secrets: Dict[str, str], source: str = "environment") -> None:
    """Validate secrets and set them as environment variables."""
    missing_required = []
    empty_secrets = []
    loaded_secrets = []
    ai_secrets_available = 0
    
    for secret_key in EXPECTED_SECRETS:
        secret_value = secrets.get(secret_key)
        env_name = SECRET_ENV_MAPPING.get(secret_key, secret_key)
        
        if secret_value is None:
            if secret_key in REQUIRED_SECRETS:
                missing_required.append(secret_key)
            continue
            
        if not secret_value.strip():
            empty_secrets.append(secret_key)
            continue
            
        # Set environment variable (decode only if from file, not if already from env)
        try:
            if source == "file":
                # File values need to be decoded
                decoded_value = _decode_b64(secret_value)
            else:
                # Environment values are already decoded
                decoded_value = secret_value
                
            if decoded_value:
                os.environ[env_name] = decoded_value
                loaded_secrets.append(env_name)
                
                # Special handling for TF_API_KEY - also set TF_TOKEN_app_terraform_io
                if secret_key == "TF_API_KEY":
                    os.environ["TF_TOKEN_app_terraform_io"] = decoded_value
                    loaded_secrets.append("TF_TOKEN_app_terraform_io")
                    print(f"✅ TF_TOKEN_app_terraform_io: loaded from {source} (duplicate of TFE_TOKEN)")
                
                if secret_key in AI_API_SECRETS:
                    ai_secrets_available += 1
                print(f"✅ {env_name}: loaded from {source}")
            else:
                empty_secrets.append(secret_key)
        except Exception as e:
            print(f"❌ Error processing {secret_key}: {e}")
            empty_secrets.append(secret_key)
    
    # Check for critical errors
    critical_errors = []
    
    # Required secrets must be present
    if missing_required:
        critical_errors.append(f"Missing required secrets: {', '.join(missing_required)}")
    
    # At least one AI API key should be available for full functionality
    if ai_secrets_available == 0:
        available_ai_keys = [SECRET_ENV_MAPPING[k] for k in AI_API_SECRETS if k in secrets]
        if not available_ai_keys:
            critical_errors.append("No AI API keys available. At least one is recommended for full functionality.")
    
    # Handle empty secrets (warn but don't fail)
    if empty_secrets:
        print(f"⚠️ Warning: Empty secrets found: {', '.join(empty_secrets)}")
    
    # Print summary
    if loaded_secrets:
        print(f"✅ Successfully loaded {len(loaded_secrets)} secrets from {source}")
        if ai_secrets_available > 0:
            print(f"🤖 AI capabilities enabled ({ai_secrets_available} API key(s) configured)")
    
    # Handle critical errors
    if critical_errors:
        error_msg = "🔐 Secret validation failed:\n"
        for error in critical_errors:
            error_msg += f"❌ {error}\n"
        
        if _is_dev_environment():
            error_msg += "\n💡 For dev environment:\n"
            error_msg += f"  - Ensure {_YAML_PATH} exists with base64-encoded values\n" 
            error_msg += f"  - Or set environment variables: {', '.join(SECRET_ENV_MAPPING.values())}\n"
        else:
            error_msg += "\n💡 For GitHub Actions:\n"
            error_msg += "  - Ensure all required secrets are configured in GitHub repository settings\n"
            error_msg += "  - Secrets should be base64-encoded\n"
        
        print(error_msg)
        sys.exit(1)


def load_secrets() -> None:
    """
    Load and validate secrets from environment variables or secrets.yaml file.
    
    Workflow:
    1. Check if secrets are available in environment variables
    2. If any env secrets exist but are empty, halt execution with error
    3. If no env secrets present and in dev environment, try loading from file
    4. Validate all secrets are present and non-empty
    5. Decode base64 values and set as environment variables
    
    Exits with error code 1 if secrets are missing or invalid.
    """
    print("🔐 Loading and validating secrets...")
    
    # First, check environment variables
    env_secrets = _get_env_secrets()
    env_secrets_present = any(v is not None for v in env_secrets.values())
    
    if env_secrets_present:
        # Environment variables are present, validate them
        print("🔍 Found secrets in environment variables")
        valid_env_secrets = {k: v for k, v in env_secrets.items() if v is not None}
        _validate_and_set_secrets(valid_env_secrets, "environment")
        return
    
    # No environment secrets found
    if _is_dev_environment():
        print("🔍 No environment secrets found, checking secrets file...")
        file_secrets = _load_secrets_from_file()
        if file_secrets:
            print(f"📁 Loading secrets from {_YAML_PATH}")
            _validate_and_set_secrets(file_secrets, "file")
            return
        else:
            print(f"❌ No secrets found in {_YAML_PATH}")
    
    # No secrets available anywhere
    error_msg = "🔐 No secrets available!\n"
    if _is_dev_environment():
        error_msg += f"💡 For dev environment, provide secrets via:\n"
        error_msg += f"  - Environment variables: {', '.join(SECRET_ENV_MAPPING.values())}\n"
        error_msg += f"  - Or mount secrets file to: {_YAML_PATH}\n"
    else:
        error_msg += "💡 For GitHub Actions, configure repository secrets\n"
    
    print(error_msg)
    sys.exit(1)


# Backward compatibility alias
load_yaml_secrets = load_secrets


def export_secrets_to_bash(output_file: str) -> None:
    """
    Export loaded secrets to a bash-sourceable file.
    This allows environment variables to persist in the parent shell.
    
    Args:
        output_file: Path to the file where bash export statements will be written
    """
    secret_keys = ['OPENAI_API_KEY', 'ANTHROPIC_API_KEY', 'GOOGLE_API_KEY', 'GROK_API_KEY', 
                   'GITHUB_TOKEN', 'DOCKERHUB_API_KEY', 'DOCKERHUB_USERNAME', 'TFE_TOKEN', 
                   'TF_TOKEN_app_terraform_io', 'PYPI_API_KEY']
    exported_count = 0
    
    with open(output_file, 'w') as f:
        for key in secret_keys:
            value = os.environ.get(key)
            if value:
                # Escape any quotes in the value
                escaped_value = value.replace('"', '\\"')
                f.write(f'export {key}="{escaped_value}"\n')
                exported_count += 1
    
    print(f'✅ {exported_count} environment variables exported to {output_file}')


if __name__ == '__main__':
    """Command-line interface for sec_utils."""
    import sys
    
    if len(sys.argv) == 1:
        # No arguments - just load secrets
        load_secrets()
    elif len(sys.argv) == 2:
        # One argument - load secrets and export to file
        output_file = sys.argv[1]
        load_secrets()
        export_secrets_to_bash(output_file)
    else:
        print("Usage:")
        print("  python3 sec_utils.py                    # Load secrets only")
        print("  python3 sec_utils.py <output_file>      # Load secrets and export to bash file")
        sys.exit(1)
