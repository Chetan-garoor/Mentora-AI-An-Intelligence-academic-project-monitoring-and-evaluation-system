from app import create_app, db
from app.models import User, Team, Project, WeeklyLog, GithubActivity
from datetime import datetime

def reconstruct():
    app = create_app()
    with app.app_context():
        # 1. Get Chetan and Vishwa
        chetan = User.query.filter_by(username='Chetan').first()
        vishwa = User.query.filter_by(username='Vishwa_jawalagi').first()
        
        if not chetan:
            print("Chetan not found. Please run restore_users.py first.")
            return

        # 2. Create Team
        team_name = "Academic Project Team"
        team = Team.query.filter_by(name=team_name).first()
        if not team:
            team = Team(name=team_name)
            db.session.add(team)
            db.session.flush()
        
        chetan.team_id = team.id
        if vishwa:
            vishwa.team_id = team.id
        team.team_lead_id = chetan.id
        
        # 3. Create Project
        project_title = "Plant Leaf Disease Detection"
        project = Project.query.filter_by(team_id=team.id).first()
        if not project:
            project = Project(
                title=project_title,
                description="Intelligent project monitoring and evaluation system focusing on agricultural disease detection.",
                github_url="https://github.com/Chetan-garoor/Plant-Leaf-Disease-Detection",
                status="Approved",
                team_id=team.id
            )
            db.session.add(project)
            db.session.flush()

        # 4. Link the existing file if possible
        # C:\Users\Chetan\OneDrive\Desktop\Final-year-p\uploads\reports\Data_AnalystUpdated.pdf
        log = WeeklyLog.query.filter_by(project_id=project.id, report_path="reports/Data_AnalystUpdated.pdf").first()
        if not log:
            log = WeeklyLog(
                week_number=1,
                report_path="reports/Data_AnalystUpdated.pdf",
                remarks="Initial project setup and data analysis.",
                student_id=chetan.id,
                project_id=project.id,
                timestamp=datetime.utcnow()
            )
            db.session.add(log)

        db.session.commit()
        print(f"Reconstructed setup for '{chetan.username}' with project '{project.title}'.")

if __name__ == '__main__':
    reconstruct()
