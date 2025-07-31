#!/usr/bin/env python3
"""
Simple script to decode specific base64 environment variables.
Only decodes the specified base64-encoded environment variables that are already set.
Independent script with its own base64 decoding function.
"""

import os
import sys
import base64
import binascii


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

# Only these environment variables need base64 decoding
BASE64_ENV_VARS = [
    "LANGSMITH_API_KEY",
    "GITHUB_TOKEN", 
    "DOCKERHUB_API_KEY",
    "DOCKERHUB_USERNAME",
    "TF_API_KEY",
    "TFE_TOKEN",
    "TF_TOKEN_app_terraform_io",
    "PYPI_API_KEY",
    "OPENAI_API_KEY",
    "GOOGLE_API_KEY",
    "ANTHROPIC_API_KEY",
    "GROK_API_KEY"
]


def decode_base64_env_vars():
    """
    Decode only the specified base64 environment variables that are already set.
    Updates the environment variables in place.
    """
    decoded_count = 0
    
    for var_name in BASE64_ENV_VARS:
        # Check if environment variable exists
        encoded_value = os.environ.get(var_name)
        
        if encoded_value:
            try:
                # Decode the base64 value
                decoded_value = _decode_b64(encoded_value)
                
                # Only update if decoding actually changed the value
                if decoded_value and decoded_value != encoded_value:
                    os.environ[var_name] = decoded_value
                    decoded_count += 1
                    print(f"✅ Decoded {var_name}")
                    
            except Exception as e:
                print(f"❌ Error decoding {var_name}: {e}", file=sys.stderr)
    
    if decoded_count > 0:
        print(f"🔓 Successfully decoded {decoded_count} base64 environment variables")
    else:
        print("ℹ️ No base64 environment variables found to decode")


def main():
    """Main function - decode base64 environment variables."""
    decode_base64_env_vars()


if __name__ == "__main__":
    main()
