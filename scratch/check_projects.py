from app import create_app, db
from app.models import Project, User

app = create_app()
with app.app_context():
    projects = Project.query.all()
    print("Projects:")
    for p in projects:
        print(f"ID: {p.id}, Title: {p.title}, Team ID: {p.team_id}")
    
    users = User.query.filter_by(role='STUDENT').all()
    print("\nStudents:")
    for u in users:
        print(f"ID: {u.id}, Username: {u.username}, Team ID: {u.team_id}")
