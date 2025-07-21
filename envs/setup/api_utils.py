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

# Simple configuration fallback for containerized environment
def get_config_value(path: str, default=None):
    """Simple config fallback that returns default values for containerized environment."""
    config_defaults = {
        "network.api_timeout": 10,
        "network.github_timeout": 15,
        "network.terraform_timeout": 30
    }
    return config_defaults.get(path, default)

def test_openai_api():
    try:
        if not os.environ.get("OPENAI_API_KEY"):
            print("❌ OpenAI API error: OPENAI_API_KEY environment variable not set.")
            return False
        client = OpenAI()
        
        # Get timeout from configuration
        api_timeout = get_config_value("network.api_timeout", 10)
        
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
            except TimeoutError:
                print(f"❌ OpenAI API error: request timed out after {api_timeout}s.")
                return False
        return True
    except Exception as e:
        print(f"❌ Open AI API error: {str(e)}")
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
        
        # Get timeout from configuration
        api_timeout = get_config_value("network.api_timeout", 10)
        
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
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("❌ Anthropic API error: ANTHROPIC_API_KEY environment variable not set.")
            return False
        client = Anthropic()
        
        # Get timeout from configuration
        api_timeout = get_config_value("network.api_timeout", 10)
        
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
            except TimeoutError:
                print(f"❌ Anthropic API error: request timed out after {api_timeout}s.")
                return False
        return True
    except Exception as e:
        print(f"❌ Anthropic API error: {str(e)}")
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
        github_timeout = get_config_value("network.github_timeout", 15)
        
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
        terraform_timeout = get_config_value("network.terraform_timeout", 30)
        
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
    github_success = test_github_api()  
    terraform_success = test_Terraform_API()  
    
    print("\nSummary:")
    print(f"OpenAI API: {'✅ Working' if openai_success else '❌ Failed'}")
    print(f"Gemini API: {'✅ Working' if gemini_success else '❌ Failed'}")
    print(f"Anthropic API: {'✅ Working' if anthropic_success else '❌ Failed'}")
    print(f"GitHub API: {'✅ Working' if github_success else '❌ Failed'}")  
    print(f"Terraform API: {'✅ Working' if terraform_success else '❌ Failed'}")

    if openai_success and gemini_success and anthropic_success and github_success and terraform_success:  # Updated condition
        print("\n🎉 All APIs are working correctly!")
    else:
        print("\n⚠️ Some APIs failed. Check the errors above.")
