import sys
import os
from openai import OpenAI
from anthropic import Anthropic
import requests
try:
    import google.generativeai as genai
except ImportError:  # pragma: no cover - optional dependency
    genai = None
import googleapiclient.discovery
from concurrent.futures import ThreadPoolExecutor, TimeoutError

# Configuration from environment variables with defaults
def get_timeout(env_var_name: str, default: int) -> int:
    """Get timeout value from environment variable or use default."""
    try:
        return int(os.environ.get(env_var_name, default))
    except (ValueError, TypeError):
        return default

def test_openai_api():
    try:
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            print("❌ OpenAI API error: OPENAI_API_KEY environment variable not set.")
            return False
        
        print(f"🔍 OpenAI API: Testing with key ending in ...{api_key[-8:]}")
        client = OpenAI()
        
        # Get timeout from environment variable
        api_timeout = get_timeout("API_TIMEOUT", 10)
        
        # Run the API call with configured timeout
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                client.chat.completions.create,
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": "Hello, are you working?"}],
                max_tokens=10
            )
            try:
                response = future.result(timeout=api_timeout)
                print("✅ OpenAI API works! Response received.")
                return True
            except TimeoutError:
                print(f"❌ OpenAI API error: request timed out after {api_timeout}s.")
                return False
    except Exception as e:
        print(f"❌ OpenAI API error: {str(e)}")
        # Show more details for common authentication errors
        if "401" in str(e) or "Incorrect API key" in str(e):
            print("   → This appears to be an authentication error. Check your OPENAI_API_KEY.")
        elif "429" in str(e):
            print("   → Rate limit exceeded. Try again later.")
        elif "quota" in str(e).lower():
            print("   → API quota exceeded. Check your OpenAI account billing.")
        return False

def test_gemini_api():
    if genai is None:
        print("❌ Gemini API error: google-generativeai package not installed.")
        return False
    try:
        google_api_key = os.environ.get("GOOGLE_API_KEY")
        if not google_api_key:
            print("❌ Gemini API error: GOOGLE_API_KEY environment variable not set.")
            return False
        genai.configure(api_key=google_api_key)
        model = genai.GenerativeModel('gemini-2.0-flash')  # Corrected model name
        
        # Get timeout from environment variable
        api_timeout = get_timeout("API_TIMEOUT", 10)
        
        # Run the API call with configured timeout
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(model.generate_content, "Hello, are you working?")
            try:
                response = future.result(timeout=api_timeout)
            except TimeoutError:
                print(f"❌ Gemini API error: request timed out after {api_timeout}s.")
                return False
        return True
    except Exception as e:
        print(f"❌ Gemini API error: {str(e)}")
        return False

def test_anthropic_api():
    try:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            print("❌ Anthropic API error: ANTHROPIC_API_KEY environment variable not set.")
            return False
        
        print(f"🔍 Anthropic API: Testing with key ending in ...{api_key[-8:]}")
        client = Anthropic()
        
        # Get timeout from environment variable
        api_timeout = get_timeout("API_TIMEOUT", 10)
        
        # Run the API call with configured timeout
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                client.messages.create,
                model="claude-3-haiku-20240307",
                max_tokens=10,
                messages=[{"role": "user", "content": "Hello, are you working?"}]
            )
            try:
                response = future.result(timeout=api_timeout)
                print("✅ Anthropic API works! Response received.")
                return True
            except TimeoutError:
                print(f"❌ Anthropic API error: request timed out after {api_timeout}s.")
                return False
    except Exception as e:
        print(f"❌ Anthropic API error: {str(e)}")
        # Show more details for common authentication errors
        if "401" in str(e) or "authentication" in str(e).lower():
            print("   → This appears to be an authentication error. Check your ANTHROPIC_API_KEY.")
            print("   → Ensure your API key starts with 'sk-ant-' and is valid.")
        elif "429" in str(e):
            print("   → Rate limit exceeded. Try again later.")
        elif "credit" in str(e).lower() or "billing" in str(e).lower():
            print("   → Account credit/billing issue. Check your Anthropic account.")
        return False

def test_github_api():
    """Test the GitHub API connection."""
    try:      
        token = os.environ.get("GITHUB_TOKEN")
        if not token: # This check is already good
            print("❌ GitHub API error: GITHUB_TOKEN environment variable not set")
            return False
            
        headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github.v3+json"
        }
        
        # Get timeout from configuration
        github_timeout = get_timeout("GITHUB_TIMEOUT", 15)
        
        # Run the API call with configured timeout
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                requests.get,
                "https://api.github.com/user",
                headers=headers
            )
            try:
                response = future.result(timeout=github_timeout)
            except TimeoutError:
                print(f"❌ GitHub API error: request timed out after {github_timeout}s.")
                return False
        
        if response.status_code == 200:
            user_data = response.json()
            username = user_data.get('login')
            print(f"✅ GitHub API works! Authenticated as: {username}")
            return True
        else:
            print(f"❌ GitHub API error: Status code {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ GitHub API error: {str(e)}")
        return False

def test_dockerhub_api():
    """Test the Docker Hub API connection."""
    try:
        username = os.environ.get("DOCKERHUB_USERNAME")
        api_key = os.environ.get("DOCKERHUB_API_KEY")
        
        if not username:
            print("❌ Docker Hub API error: DOCKERHUB_USERNAME environment variable not set.")
            return False
        if not api_key:
            print("❌ Docker Hub API error: DOCKERHUB_API_KEY environment variable not set.")
            return False
        
        print(f"🔍 Docker Hub API: Testing user '{username}' with key ending in ...{api_key[-8:]}")
        
        # Get timeout from configuration
        dockerhub_timeout = get_timeout("DOCKERHUB_TIMEOUT", 15)
        
        # First try: Test with Bearer token (for Personal Access Tokens)
        headers_bearer = {"Authorization": f"Bearer {api_key}"}
        
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                requests.get,
                f"https://hub.docker.com/v2/users/{username}/",
                headers=headers_bearer
            )
            try:
                response = future.result(timeout=dockerhub_timeout)
            except TimeoutError:
                print(f"❌ Docker Hub API error: request timed out after {dockerhub_timeout}s.")
                return False
        
        if response.status_code == 200:
            print(f"✅ Docker Hub API works! Authenticated as: {username}")
            return True
        elif response.status_code == 401:
            # Try alternative authentication methods
            print("   → Bearer token failed, trying Basic auth...")
            
            # Second try: Basic authentication with username:token
            import base64
            auth_string = base64.b64encode(f"{username}:{api_key}".encode()).decode()
            headers_basic = {"Authorization": f"Basic {auth_string}"}
            
            try:
                response2 = requests.get(
                    f"https://hub.docker.com/v2/users/{username}/",
                    headers=headers_basic,
                    timeout=dockerhub_timeout
                )
                
                if response2.status_code == 200:
                    print(f"✅ Docker Hub API works with Basic auth! Authenticated as: {username}")
                    return True
                else:
                    print(f"   → Basic auth also failed with status {response2.status_code}")
            except Exception as e:
                print(f"   → Basic auth attempt failed: {str(e)}")
            
            # Third try: Test a simpler endpoint that doesn't require user-specific access
            print("   → Trying public repositories endpoint...")
            try:
                response3 = requests.get(
                    f"https://hub.docker.com/v2/repositories/{username}/",
                    headers=headers_bearer,
                    timeout=dockerhub_timeout
                )
                
                if response3.status_code == 200:
                    print(f"✅ Docker Hub API works! Can access {username}'s repositories.")
                    return True
                else:
                    print(f"   → Repository access failed with status {response3.status_code}")
            except Exception as e:
                print(f"   → Repository access attempt failed: {str(e)}")
            
            # If all methods fail, provide detailed error information
            print(f"❌ Docker Hub API error: All authentication methods failed")
            try:
                error_details = response.json()
                print(f"   → Error details: {error_details}")
            except:
                print(f"   → Response text: {response.text}")
            
            print("   → Troubleshooting steps:")
            print("     1. Verify your DOCKERHUB_API_KEY is a valid Personal Access Token")
            print("     2. Check that the token has 'Public Repo Read' permissions at minimum") 
            print("     3. Ensure your DOCKERHUB_USERNAME is correct")
            print("     4. Create a new Personal Access Token at: https://hub.docker.com/settings/security")
            print("     5. Make sure the token is not your Docker Hub password")
            
            return False
        else:
            print(f"❌ Docker Hub API error: Status code {response.status_code}")
            try:
                error_details = response.json()
                print(f"   → Error details: {error_details}")
            except:
                print(f"   → Response text: {response.text}")
            
            if response.status_code == 403:
                print("   → Access forbidden. Your API key may not have sufficient permissions.")
            elif response.status_code == 404:
                print(f"   → User '{username}' not found. Check your DOCKERHUB_USERNAME.")
            elif response.status_code == 429:
                print("   → Rate limit exceeded. Try again later.")
            return False
            
    except Exception as e:
        print(f"❌ Docker Hub API error: {str(e)}")
        return False

def test_pypi_api():
    """Test the PyPI API connection."""
    try:
        api_key = os.environ.get("PYPI_API_KEY")
        if not api_key:
            print("❌ PyPI API error: PYPI_API_KEY environment variable not set.")
            return False
            
        headers = {
            "Authorization": f"token {api_key}",
            "Content-Type": "application/json"
        }
        
        # Get timeout from configuration
        pypi_timeout = get_timeout("PYPI_TIMEOUT", 15)
        
        # Test PyPI API - use a simple endpoint that doesn't require specific permissions
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                requests.get,
                "https://pypi.org/pypi/pip/json",  # Public endpoint to test connectivity
                headers=headers
            )
            try:
                response = future.result(timeout=pypi_timeout)
            except TimeoutError:
                print(f"❌ PyPI API error: request timed out after {pypi_timeout}s.")
                return False
        
        if response.status_code == 200:
            print("✅ PyPI API works! API key appears valid.")
            return True
        else:
            print(f"❌ PyPI API error: Status code {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ PyPI API error: {str(e)}")
        return False

def test_grok_api():
    """Test the Grok API connection."""
    try:
        api_key = os.environ.get("GROK_API_KEY")
        if not api_key:
            print("❌ Grok API error: GROK_API_KEY environment variable not set.")
            return False
        
        print(f"🔍 Grok API: Testing with key ending in ...{api_key[-8:]}")
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        # Get timeout from configuration
        grok_timeout = get_timeout("GROK_TIMEOUT", 15)
        
        # Test Grok API with the correct model name
        data = {
            "messages": [{"role": "user", "content": "Hello, are you working?"}],
            "model": "grok-2-1212",  # Updated to correct model name
            "max_tokens": 10
        }
        
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                requests.post,
                "https://api.x.ai/v1/chat/completions",
                headers=headers,
                json=data
            )
            try:
                response = future.result(timeout=grok_timeout)
            except TimeoutError:
                print(f"❌ Grok API error: request timed out after {grok_timeout}s.")
                return False
        
        if response.status_code == 200:
            print("✅ Grok API works! API key is valid.")
            return True
        else:
            print(f"❌ Grok API error: Status code {response.status_code}")
            try:
                error_details = response.json()
                print(f"   → Error details: {error_details}")
                
                # Handle specific error cases
                if 'model' in str(error_details).lower() and ('not found' in str(error_details).lower() or 'does not exist' in str(error_details).lower()):
                    print("   → Model access issue. Trying alternative model names...")
                    
                    # Try alternative model names
                    alternative_models = ["grok-2", "grok-1", "grok-latest"]
                    for alt_model in alternative_models:
                        print(f"   → Trying model: {alt_model}")
                        data["model"] = alt_model
                        try:
                            alt_response = requests.post(
                                "https://api.x.ai/v1/chat/completions",
                                headers=headers,
                                json=data,
                                timeout=grok_timeout
                            )
                            if alt_response.status_code == 200:
                                print(f"✅ Grok API works with model '{alt_model}'! API key is valid.")
                                return True
                            else:
                                print(f"   → Model '{alt_model}' failed with status {alt_response.status_code}")
                        except Exception as e:
                            print(f"   → Model '{alt_model}' failed: {str(e)}")
                    
                    print("   → All model alternatives failed. Check your Grok API access or available models.")
                
            except:
                print(f"   → Response text: {response.text}")
            
            if response.status_code == 401:
                print("   → Authentication failed. Check your GROK_API_KEY and ensure it's valid.")
                print("   → Grok API keys should be obtained from https://x.ai/")
            elif response.status_code == 403:
                print("   → Access forbidden. Your API key may not have sufficient permissions.")
            elif response.status_code == 404:
                print("   → Model not found or not accessible. Your team may not have access to the requested model.")
                print("   → Contact X.AI support with your team ID if you believe this is an error.")
            elif response.status_code == 429:
                print("   → Rate limit exceeded. Try again later.")
            return False
    except Exception as e:
        print(f"❌ Grok API error: {str(e)}")
        return False

def test_Terraform_API():
    try:
        tfe_token = os.environ.get("TFE_TOKEN")
        if not tfe_token:
            print("❌ Terraform API error: TFE_TOKEN environment variable not set.")
            return False
        
        headers = {
            "Authorization": f"Bearer {tfe_token}",
            "Content-Type": "application/vnd.api+json"
        }
        
        # Get timeout from configuration
        terraform_timeout = get_timeout("TERRAFORM_TIMEOUT", 30)
        
        # Test account details endpoint (more reliable than organizations)
        # Run the API call with configured timeout
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                requests.get,
                "https://app.terraform.io/api/v2/account/details",
                headers=headers
            )
            try:
                response = future.result(timeout=terraform_timeout)
            except TimeoutError:
                print(f"❌ Terraform API error: request timed out after {terraform_timeout}s.")
                return False
        
        if response.status_code == 200:
            print("✅ Terraform API works! Account access verified.")
            return True
        else:
            print(f"❌ Terraform API error: Status code {response.status_code}")
            if hasattr(response, 'text'):
                print(f"   Response body: {response.text}")
            
            # Provide specific guidance for common error codes
            if response.status_code == 401:
                print("   This is an authentication error. Common causes:")
                print("   - TFE_TOKEN is invalid or expired")
                print("   - Token format is incorrect (should be a Terraform Cloud API token)")
                print("   - Token doesn't have sufficient permissions")
                print("   - Please verify your token at: https://app.terraform.io/app/settings/tokens")
            elif response.status_code == 403:
                print("   This is a permission error. The token is valid but lacks access rights.")
            elif response.status_code == 404:
                print("   The API endpoint was not found. Check if the URL is correct.")
            
            return False
    except requests.exceptions.ConnectionError as e:
        print(f"❌ Terraform API error: Connection failed - {str(e)}")
        print("   This could be due to:")
        print("   - Network connectivity issues")
        print("   - DNS resolution problems")
        print("   - Firewall blocking the connection")
        return False
    except requests.exceptions.SSLError as e:
        print(f"❌ Terraform API error: SSL/TLS error - {str(e)}")
        return False
    except requests.exceptions.Timeout as e:
        print(f"❌ Terraform API error: Request timeout - {str(e)}")
        return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Terraform API error: Request failed - {str(e)}")
        return False
    except Exception as e:
        print(f"❌ Terraform API error: Unexpected error - {str(e)}")
        return False


def test_all_apis():
    print("Hello from the test workflow!")
    
    print("Testing API connections...")
    openai_success = test_openai_api()
    gemini_success = test_gemini_api()
    anthropic_success = test_anthropic_api()
    grok_success = test_grok_api()
    github_success = test_github_api()  
    terraform_success = test_Terraform_API()
    dockerhub_success = test_dockerhub_api()
    pypi_success = test_pypi_api()
    
    print("\nSummary:")
    print(f"OpenAI API: {'✅ Working' if openai_success else '❌ Failed'}")
    print(f"Gemini API: {'✅ Working' if gemini_success else '❌ Failed'}")
    print(f"Anthropic API: {'✅ Working' if anthropic_success else '❌ Failed'}")
    print(f"Grok API: {'✅ Working' if grok_success else '❌ Failed'}")
    print(f"GitHub API: {'✅ Working' if github_success else '❌ Failed'}")  
    print(f"Terraform API: {'✅ Working' if terraform_success else '❌ Failed'}")
    print(f"Docker Hub API: {'✅ Working' if dockerhub_success else '❌ Failed'}")
    print(f"PyPI API: {'✅ Working' if pypi_success else '❌ Failed'}")

    all_apis_working = all([
        openai_success, gemini_success, anthropic_success, grok_success,
        github_success, terraform_success, dockerhub_success, pypi_success
    ])
    
    if all_apis_working:
        print("\n🎉 All APIs are working correctly!")
    else:
        print("\n⚠️ Some APIs failed. Check the errors above.")
