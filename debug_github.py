import os
import requests
from dotenv import load_dotenv

load_dotenv()

token = os.environ.get('GITHUB_TOKEN')
print(f"Token present: {bool(token)}")
if token:
    print(f"Token starts with: {token[:7]}...")

headers = {'Accept': 'application/vnd.github.v3+json'}
if token:
    headers['Authorization'] = f'token {token}'

# Test token validity
response = requests.get("https://api.github.com/user", headers=headers)
print(f"Token Check Status: {response.status_code}")
if response.status_code != 200:
    print(f"Error: {response.json().get('message')}")

# Check project in DB
from app import create_app
from app.models import Project

app = create_app()
with app.app_context():
    projects = Project.query.all()
    for p in projects:
        print(f"Project ID: {p.id}, Title: {p.title}, URL: {p.github_url}")
        
        # Test specific project URL
        if p.github_url:
            parts = p.github_url.strip('/').split('/')
            if len(parts) >= 2:
                owner, repo = parts[-2], parts[-1]
                api_url = f"https://api.github.com/repos/{owner}/{repo}/stats/contributors"
                print(f"Checking API URL: {api_url}")
                res = requests.get(api_url, headers=headers)
                print(f"API Check Status: {res.status_code}")
