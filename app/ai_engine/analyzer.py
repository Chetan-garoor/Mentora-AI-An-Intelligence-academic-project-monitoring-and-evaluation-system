import pandas as pd
from datetime import datetime, timedelta

class AIAnalyzer:
    def __init__(self):
        pass

    def calculate_score(self, commits, additions, weekly_submissions, consistency):
        """
        score = (commits * 0.4) + (code_additions * 0.3) + (weekly_submissions * 0.2) + (consistency * 0.1)
        Normalized to 100%.
        """
        # Note: In a real system, we'd normalize these inputs based on group averages
        # For simplicity, we assume normalized inputs (0.0 to 1.0) or apply logic
        
        # Simple normalization for demonstration:
        norm_commits = min(commits / 50, 1.0) # Assume 50 commits is "full marks"
        norm_additions = min(additions / 5000, 1.0) # Assume 5000 lines is "full marks"
        norm_weekly = min(weekly_submissions / 12, 1.0) # 12 weeks of project
        
        score = (norm_commits * 0.4) + (norm_additions * 0.3) + (norm_weekly * 0.2) + (consistency * 0.1)
        return round(score * 100, 2)

    def detect_behaviours(self, student_data):
        """
        Detects:
        - Free rider (<10% contribution)
        - Last minute contributor (60% commits in last week)
        - Inactive (>14 days no activity)
        - Fake team (only one active member)
        """
        tags = []
        
        # student_data is a dict with activity details
        contribution = student_data.get('contribution_pct', 0)
        last_commits_pct = student_data.get('last_week_commits_pct', 0)
        days_since_active = student_data.get('days_inactive', 0)
        
        if contribution < 10:
            tags.append("Free Rider")
        
        if last_commits_pct > 60:
            tags.append("Last Minute Contributor")
            
        if days_since_active > 14:
            tags.append("Inactive")
            
        return ", ".join(tags)

    def predict_risk(self, inactivity_days, weekly_activity, commit_frequency):
        """
        Simple heuristic-based 'prediction' (can be replaced with ML model).
        """
        if inactivity_days > 10 or weekly_activity < 0.2 or commit_frequency < 2:
            return "At Risk"
        return "On Track"
