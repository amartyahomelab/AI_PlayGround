#!/usr/bin/env python3
"""
Decode base64 environment variables and export them as shell export statements.
This script is designed to be called from a bash entrypoint script to make
decoded environment variables available to the shell and all subsequent processes.
"""

import sys
import os


def decode_and_export_env_vars():
    """
    Decode base64 environment variables and output shell export statements.
    This allows the decoded values to be sourced by the calling bash script.
    """
    try:
        # Import decode_env functionality
        sys.path.insert(0, '/opt')
        from decode_env import decode_base64_env_vars
        
        # Decode the base64 environment variables in-place
        decode_base64_env_vars()
        
        # Output shell script header
        print("#!/bin/bash")
        
        # List of variables that might have been decoded
        env_vars = [
            "LANGSMITH_API_KEY", "GITHUB_TOKEN", "DOCKERHUB_API_KEY", 
            "DOCKERHUB_USERNAME", "TF_API_KEY", "TFE_TOKEN", 
            "TF_TOKEN_app_terraform_io", "PYPI_API_KEY", 
            "OPENAI_API_KEY", "GOOGLE_API_KEY", "ANTHROPIC_API_KEY", "GROK_API_KEY"
        ]
        
        exported_count = 0
        for var_name in env_vars:
            value = os.environ.get(var_name, '')
            if value:
                # Properly escape special characters for bash
                escaped_value = value.replace("'", "'\"'\"'").replace("$", "\\$").replace("`", "\\`")
                print(f"export {var_name}='{escaped_value}'")
                exported_count += 1
        
        print(f"echo '✅ Exported {exported_count} decoded environment variables to shell'")
        
    except Exception as e:
        print(f"echo '❌ Error decoding environment variables: {e}'")
        sys.exit(1)


if __name__ == "__main__":
    decode_and_export_env_vars()
