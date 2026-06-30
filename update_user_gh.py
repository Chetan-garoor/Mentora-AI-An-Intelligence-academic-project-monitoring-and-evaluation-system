from app import create_app, db
from app.models import User

app = create_app()
with app.app_context():
    # Update the main user
    u = User.query.filter_by(username='revan').first()
    if u:
        u.github_username = 'Revanasiddappaa0607'
        db.session.commit()
        print(f"Updated user '{u.username}' with GitHub username '{u.github_username}'.")
    else:
        print("User 'revan' not found.")
        
    # Also update 'revan2' if it exists for completeness
    u2 = User.query.filter_by(username='revan2').first()
    if u2:
        u2.github_username = 'Revanasiddappaa0607'
        db.session.commit()
        print(f"Updated user '{u2.username}' with GitHub username '{u2.github_username}'.")
