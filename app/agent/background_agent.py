from apscheduler.schedulers.background import BackgroundScheduler
from app.services.github_service import GitHubService
from app.services.ai_analyzer import AIAnalyzer
from app.models import Project, User, Notification, db, FacultyAssignment
from datetime import datetime

def collect_and_analyze(app):
    """
    Automated Agent Loop: collect_data() -> analyze() -> decide() -> act()
    """
    with app.app_context():
        # Only analyze approved projects
        projects = Project.query.filter(Project.status.in_(['Approved', 'Final Approved'])).all()
        
        for project in projects:
            # 1. collect_data()
            gh = GitHubService()
            gh.fetch_repo_activity(project.id)
            
            # 2. analyze() & 3. decide() & 4. act()
            team_members = project.team.members if project.team else []
            active_count = 0
            
            # Run ML Batch Analysis for the whole team
            AIAnalyzer.batch_ml_analysis(project.id)
            
            for student in team_members:
                from app.models import AIEvaluation
                eval_record = AIEvaluation.query.filter_by(student_id=student.id, project_id=project.id).first()
                
                if not eval_record: continue
                
                # Update active count for 'Fake Team' detection
                if eval_record.contribution_score > 5:
                    active_count += 1
                
                # decicide() & act()
                if "Inactive" in eval_record.behaviour_tags:
                    # Specific rules: 7 days warn student, 14 days alert faculty
                    # Behaviour tag 'Inactive' is triggered at 14 days in AIAnalyzer.
                    # We'll check the last activity manually for the 7-day rule.
                    from app.models import GithubActivity
                    last_act = GithubActivity.query.filter_by(student_id=student.id).order_by(GithubActivity.date_recorded.desc()).first()
                    
                    if last_act:
                        days_inactive = (datetime.utcnow() - last_act.date_recorded).days
                        
                        if days_inactive >= 14:
                            # Alert faculty
                            assignment = FacultyAssignment.query.filter_by(team_id=project.team_id).first()
                            if assignment:
                                msg = f"ALERT: Student {student.username} has been inactive for {days_inactive} days on project {project.title}."
                                db.session.add(Notification(user_id=assignment.faculty_id, message=msg))
                        elif days_inactive >= 7:
                            # Warn student
                            msg = f"WARNING: You have been inactive for {days_inactive} days on your project. Please update your progress."
                            db.session.add(Notification(user_id=student.id, message=msg))

            # Flag suspicious (Fake Team: only one active member)
            if len(team_members) > 1 and active_count == 1:
                msg = f"FLAG: Project '{project.title}' is suspicious. Only one member is contributing (Possible Fake Team)."
                # Notify coordinator
                if project.coordinator_id:
                    db.session.add(Notification(user_id=project.coordinator_id, message=msg))

        db.session.commit()
        print(f"[{datetime.utcnow()}] Background Agent Loop Completed.")

def start_agent(app):
    scheduler = BackgroundScheduler()
    # Runs daily as requested
    scheduler.add_job(func=collect_and_analyze, trigger="interval", days=1, args=[app])
    scheduler.start()
    print("AI Automated Agent Started (Daily Interval).")
