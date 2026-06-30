import requests
import os
from datetime import datetime
from app.models import GithubActivity, User, Project
from app import db

class GitHubService:
    def __init__(self, token=None):
        self.token = token or os.environ.get('GITHUB_TOKEN')
        self.headers = {'Accept': 'application/vnd.github.v3+json'}
        if self.token:
            self.headers['Authorization'] = f'token {self.token}'

    def fetch_repo_activity(self, project_id):
        project = Project.query.get(project_id)
        if not project or not project.github_url:
            return False
            
        # Extract owner/repo from URL
        url = project.github_url.strip().rstrip('/')
        if url.endswith('.git'):
            url = url[:-4]
            
        parts = url.split('/')
        if len(parts) < 2: 
            print(f"DEBUG: Invalid GitHub URL structure: {project.github_url}")
            return False
            
        owner, repo = parts[-2], parts[-1]
        
        api_url = f"https://api.github.com/repos/{owner}/{repo}/stats/contributors"
        
        if not self.token:
            print("WARNING: GitHub Token not found. Live tracking will fail.")
            return False

        try:
            # 1. Immediate Source: Get commit count directly (Never returns 202)
            # We fetch for each student in the team
            updated = False
            for student in project.team.members:
                gh_username = student.github_username or student.username
                commits_url = f"https://api.github.com/repos/{owner}/{repo}/commits?author={gh_username}&per_page=1"
                c_res = requests.get(commits_url, headers=self.headers, timeout=10)
                
                commit_count = 0
                if c_res.status_code == 200:
                    # Check Link header for total count
                    link = c_res.headers.get('Link')
                    if link and 'rel="last"' in link:
                        import re
                        match = re.search(r'page=(\d+)>; rel="last"', link)
                        if match:
                            commit_count = int(match.group(1))
                    else:
                        # If no link header, it means only one page of results exists
                        commit_count = len(c_res.json())
                
                # 2. Detailed Source: Try stats for additions/deletions (May return 202)
                stats_res = requests.get(api_url, headers=self.headers, timeout=10)
                additions, deletions = 0, 0
                
                if stats_res.status_code == 200:
                    stats_data = stats_res.json()
                    for contributor in stats_data:
                        if contributor['author']['login'] == gh_username:
                            additions = sum(w['a'] for w in contributor['weeks'])
                            deletions = sum(w['d'] for w in contributor['weeks'])
                            # If stats are ready, the commit count here is more accurate for long history
                            commit_count = max(commit_count, contributor['total'])
                            break
                
                # Only update if we found something or if we want to reset to 0 for real tracking
                # We always create a new record for "real-time" feel
                activity = GithubActivity(
                    student_id=student.id,
                    commits=commit_count,
                    additions=additions,
                    deletions=deletions,
                    last_activity=datetime.utcnow()
                )
                db.session.add(activity)
                updated = True
                
            if updated:
                db.session.commit()
                return True
            return False
            
        except Exception as e:
            print(f"Error fetching GitHub activity: {e}")
            return False

    def get_recent_commits(self, project_id, limit=5):
        project = Project.query.get(project_id)
        if not project or not project.github_url:
            return []
            
        url = project.github_url.strip().rstrip('/')
        if url.endswith('.git'):
            url = url[:-4]
            
        parts = url.split('/')
        if len(parts) < 2: 
            return []
            
        owner, repo = parts[-2], parts[-1]
        api_url = f"https://api.github.com/repos/{owner}/{repo}/commits?per_page={limit}"
        
        try:
            res = requests.get(api_url, headers=self.headers, timeout=10)
            if res.status_code == 200:
                commits = []
                for item in res.json():
                    commits.append({
                        'sha': item['sha'][:7],
                        'message': item['commit']['message'],
                        'author': item['commit']['author']['name'],
                        'date': item['commit']['author']['date'],
                        'url': item['html_url']
                    })
                return commits
            return []
        except Exception as e:
            print(f"Error fetching commits: {e}")
            return []

    # Mock version removed to ensure strictly real-time data tracking.
