from app.models import GithubActivity, WeeklyLog, AIEvaluation, User, Project, db, PeerEvaluation
from datetime import datetime, timedelta
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import MinMaxScaler
import numpy as np

class AIAnalyzer:
    @staticmethod
    def analyze_student_contribution(student_id, project_id, global_stats=None):
        student = User.query.get(student_id)
        project = Project.query.get(project_id)
        if not student or not project: return None
        
        # 1. Fetch Data
        activities = GithubActivity.query.filter_by(student_id=student.id).order_by(GithubActivity.date_recorded.asc()).all()
        logs = WeeklyLog.query.filter_by(student_id=student.id, project_id=project.id).all()
        
        latest_activity = activities[-1] if activities else None
        total_commits = latest_activity.commits if latest_activity else 0
        total_additions = latest_activity.additions if latest_activity else 0
        total_logs = len(logs)
        consistency = latest_activity.consistency_score if latest_activity else 0.5
        
        # We process scoring via the ML batch method if called from background agent.
        # This single-student method defaults to a heuristic evaluation for real-time single requests.
        norm_commits = min(total_commits / 20, 1.0)
        norm_additions = min(total_additions / 1000, 1.0)
        norm_logs = min(total_logs / 12, 1.0)
        
        evals = PeerEvaluation.query.filter_by(evaluatee_id=student.id, project_id=project.id).all()
        avg_peer_score = sum(e.score for e in evals) / len(evals) if evals else 3.0 # Default neutral
        norm_peer = (avg_peer_score - 1) / 4.0 # Scale 1-5 to 0.0-1.0
        
        raw_score = (norm_commits * 0.3) + (norm_additions * 0.2) + (norm_logs * 0.2) + (norm_peer * 0.2) + (consistency * 0.1)
        percentage_score = round(raw_score * 100, 2)
        
        tags = []
        if percentage_score < 10:
            tags.append("Free Rider")
            
        last_activity = activities[-1].last_activity if activities else None
        if not last_activity or (datetime.utcnow() - last_activity).days > 14:
            tags.append("Inactive")
            
        risk = "ON_TRACK"
        if percentage_score < 30 or "Inactive" in tags:
            risk = "AT_RISK"
            
        eval_record = AIEvaluation.query.filter_by(student_id=student.id, project_id=project.id).first()
        if not eval_record:
            eval_record = AIEvaluation(student_id=student.id, project_id=project.id)
            db.session.add(eval_record)
            
        eval_record.contribution_score = percentage_score
        eval_record.behaviour_tags = ", ".join(tags) if tags else "Good Contributor"
        eval_record.risk_level = risk
        eval_record.last_updated = datetime.utcnow()
        
        db.session.commit()
        return eval_record

    @staticmethod
    def batch_ml_analysis(project_id=None):
        """
        Uses scikit-learn IsolationForest for anomaly detection to identify free riders.
        If project_id is provided, analyzes only that project's members relative to each other.
        Otherwise, analyzes all students in active projects.
        """
        query = db.session.query(
            User.id.label('student_id'),
            Project.id.label('project_id'),
        ).join(Project, User.team_id == Project.team_id)
        
        if project_id:
            query = query.filter(Project.id == project_id)
        else:
            query = query.filter(Project.status.in_(['Approved', 'Final Approved']))
            
        students_data = query.all()
        if not students_data:
            return 0
            
        data = []
        for row in students_data:
            sid = row.student_id
            pid = row.project_id
            
            activities = GithubActivity.query.filter_by(student_id=sid).order_by(GithubActivity.date_recorded.asc()).all()
            logs = WeeklyLog.query.filter_by(student_id=sid, project_id=pid).all()
            
            latest_activity = activities[-1] if activities else None
            commits = latest_activity.commits if latest_activity else 0
            additions = latest_activity.additions if latest_activity else 0
            logs_count = len(logs)
            consistency = latest_activity.consistency_score if latest_activity else 0.5
            
            last_activity = latest_activity.last_activity if latest_activity else None
            days_inactive = (datetime.utcnow() - last_activity).days if last_activity else 999
            
            evals = PeerEvaluation.query.filter_by(evaluatee_id=sid, project_id=pid).all()
            avg_peer_score = sum(e.score for e in evals) / len(evals) if evals else 3.0
            
            data.append({
                'student_id': sid,
                'project_id': pid,
                'commits': commits,
                'additions': additions,
                'logs': logs_count,
                'consistency': consistency,
                'days_inactive': days_inactive,
                'peer_score': avg_peer_score
            })
            
        df = pd.DataFrame(data)
        if len(df) < 2:
            # Not enough data for ML, fallback to single logic
            for d in data:
                AIAnalyzer.analyze_student_contribution(d['student_id'], d['project_id'])
            return len(data)

        # Features for ML
        features = ['commits', 'additions', 'logs', 'consistency', 'peer_score']
        X = df[features].copy()
        
        # Scale features
        scaler = MinMaxScaler()
        X_scaled = scaler.fit_transform(X)
        
        # Calculate a unified score based on scaled features (weighted)
        # Weights: Commits(30%), Additions(20%), Logs(20%), Consistency(10%), Peer Score(20%)
        weights = np.array([0.3, 0.2, 0.2, 0.1, 0.2])
        scores = np.dot(X_scaled, weights) * 100
        df['contribution_score'] = scores.round(2)
        
        # Anomaly Detection algorithm (Isolation Forest)
        # We assume contamination is at most 15% (percentage of free riders expected)
        iso_forest = IsolationForest(n_estimators=100, contamination=0.15, random_state=42)
        
        # Predict outliers (-1 for outliers, 1 for inliers)
        # We try to fit and catch cases where data is too small or too uniform
        try:
            df['outlier'] = iso_forest.fit_predict(X_scaled)
        except Exception:
            df['outlier'] = 1  # Failsafe if ML throws bounds error on homogeneous data
            
        active_count = 0
        
        # Write back evaluations
        for idx, row in df.iterrows():
            sid = int(row['student_id'])
            pid = int(row['project_id'])
            score = row['contribution_score']
            is_outlier = row['outlier'] == -1
            days_inactive = row['days_inactive']
            
            tags = []
            
            # An outlier with a low score is definitely a Free Rider
            if is_outlier and score < df['contribution_score'].mean():
                tags.append("Free Rider")
            elif score < 10:  # Hard threshold failsafe
                tags.append("Free Rider")
                
            if days_inactive > 14:
                tags.append("Inactive")
                
            risk = "ON_TRACK"
            if ("Free Rider" in tags) or ("Inactive" in tags) or score < 30:
                risk = "AT_RISK"
                
            eval_record = AIEvaluation.query.filter_by(student_id=sid, project_id=pid).first()
            if not eval_record:
                eval_record = AIEvaluation(student_id=sid, project_id=pid)
                db.session.add(eval_record)
                
            eval_record.contribution_score = score
            eval_record.behaviour_tags = ", ".join(tags) if tags else "Good Contributor"
            eval_record.risk_level = risk
            eval_record.last_updated = datetime.utcnow()
            
            # Update Active count equivalent for Fake team check
            if score > 5:
                active_count += 1
                
        db.session.commit()
        return len(df)
