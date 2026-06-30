import hashlib
import random
from urllib.parse import urlparse

class CodeScanner:
    """
    Simulates an advanced AI-driven code analyzer that scans GitHub repositories
    for plagiarism, heavily-templated code, and generative AI boilerplate.
    For this academic demo, it generates deterministic heuristics based on the repo URL.
    """
    
    @staticmethod
    def analyze_repository(github_url):
        if not github_url:
            return {
                "originality_score": 0,
                "risk_level": "UNKNOWN",
                "insights": ["No repository provided for scanning."]
            }
            
        # Create deterministic seed based on URL so the score stays consistent
        parsed = urlparse(github_url)
        repo_path = parsed.path.strip('/')
        seed_hash = int(hashlib.md5(repo_path.encode()).hexdigest(), 16)
        random.seed(seed_hash)
        
        # Simulate advanced heuristics
        base_originality = random.randint(70, 98)
        
        insights = []
        if base_originality > 90:
            insights.append("High originality detected. Complex custom logic identified in core modules.")
            risk = "LOW"
        elif base_originality > 80:
            insights.append("Standard academic boilerplate detected. Moderate use of common framework structures.")
            risk = "MEDIUM"
        else:
            insights.append("Warning: High structural similarity to known public repositories.")
            insights.append("Potential heavy reliance on LLM-generated generic patterns.")
            risk = "HIGH"
            
        # Specific simulated file checks
        files_scanned = random.randint(15, 120)
        insights.append(f"Deep structural scan completed across {files_scanned} source files.")
        
        return {
            "originality_score": base_originality,
            "risk_level": risk,
            "insights": insights
        }
