#!/usr/bin/env python3
"""
Export environment variables to a shell script that can be sourced.
This script loads secrets and generates shell export statements.
"""
import sys
import os
sys.path.insert(0, '/home/user/app/envs/setup')

def export_environment():
    """Export environment variables by generating shell export statements."""
    try:
        # Temporarily redirect stdout to suppress print statements from sec_utils
        import io
        import contextlib
        
        f = io.StringIO()
        with contextlib.redirect_stdout(f):
            from sec_utils import load_secrets_to_dict
            secrets = load_secrets_to_dict()
        
        if not secrets:
            return
            
        # Generate export statements for shell
        for env_name, env_value in secrets.items():
            # Clean non-ASCII characters first, then escape
            clean_value = env_value.encode('ascii', 'ignore').decode('ascii')
            escaped_value = clean_value.replace("'", "'\\''")
            print(f"export {env_name}='{escaped_value}'")
            
    except Exception as e:
        print(f"# Error loading secrets: {e}", file=sys.stderr)

if __name__ == "__main__":
    export_environment()
