#!/usr/bin/env python3
"""
Test script to verify environment setup and API connectivity.
"""
import sys
import os

def test_environment_setup():
    """Test that environment variables are properly loaded."""
    print("🔍 Checking environment variables...")
    
    expected_vars = [
        "OPENAI_API_KEY",
        "ANTHROPIC_API_KEY", 
        "GOOGLE_API_KEY",
        "GITHUB_TOKEN",
        "TFE_TOKEN"
    ]
    
    found_vars = []
    missing_vars = []
    
    for var in expected_vars:
        if os.environ.get(var):
            found_vars.append(var)
            # Show partial value for security
            value = os.environ[var]
            masked_value = value[:8] + "..." + value[-4:] if len(value) > 12 else "***"
            print(f"  ✅ {var}: {masked_value}")
        else:
            missing_vars.append(var)
            print(f"  ❌ {var}: Not set")
    
    print(f"\n📊 Summary: {len(found_vars)} found, {len(missing_vars)} missing")
    return len(found_vars) > 0


def main():
    print("🚀 Testing environment setup...")
    
    # Test environment variables
    env_ok = test_environment_setup()
    
    if not env_ok:
        print("\n⚠️ No environment variables found. Make sure secrets are loaded properly.")
        return 1
    
    # Test API utilities
    print("\n🔌 Testing API utilities...")
    try:
        sys.path.insert(0, '/home/user/app/envs/setup')
        from api_utils import test_all_apis
        test_all_apis()
        print("✅ API utilities test completed")
    except Exception as e:
        print(f"❌ API utilities test failed: {e}")
        return 1
    
    print("\n🎉 Environment test completed successfully!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
