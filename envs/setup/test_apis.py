#!/usr/bin/env python3
"""
Test all API connections to verify they are working.
This script is called by entrypoint.sh to validate API connectivity.
"""

import sys
from api_utils import test_all_apis

def main():
    """Test all API connections."""
    try:
        print('🧪 Starting API connection tests...')
        test_all_apis()
        print('✅ All API tests completed')
    except Exception as e:
        print(f'❌ Error testing APIs: {e}')
        # Don't exit with error - we want the container to start even if some APIs fail
        # sys.exit(1)

if __name__ == '__main__':
    main()
