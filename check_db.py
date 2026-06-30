from app import create_app, db
from app.models import User, GithubActivity

app = create_app()

with app.app_context():
    user = User.query.filter_by(username='Chetan').first()
    if user:
        activities = GithubActivity.query.filter_by(student_id=user.id).order_by(GithubActivity.date_recorded.desc()).all()
        print(f"Chetan's activities ({len(activities)} total):")
        for act in activities:
            print(f"Date: {act.date_recorded}, Commits: {act.commits}, Additions: {act.additions}, Deletions: {act.deletions}")
    else:
        print("User Chetan not found.")
