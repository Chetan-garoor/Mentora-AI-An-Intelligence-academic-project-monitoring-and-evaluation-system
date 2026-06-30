from app import create_app, db
from app.models import User, Team, Project
from werkzeug.security import generate_password_hash

def restore():
    app = create_app()
    with app.app_context():
        # Check if they exist
        users_to_add = [
            {'username': 'Chetan', 'email': 'chetan@example.com', 'role': 'STUDENT', 'gh': 'Chetan-garoor'},
            {'username': 'Vishwa_jawalagi', 'email': 'vishwa@example.com', 'role': 'STUDENT', 'gh': 'Revanasiddappaa0607'}
        ]
        
        for u_data in users_to_add:
            existing = User.query.filter_by(username=u_data['username']).first()
            if not existing:
                new_user = User(
                    username=u_data['username'],
                    email=u_data['email'],
                    password=generate_password_hash('password123'),
                    role=u_data['role'],
                    github_username=u_data['gh']
                )
                db.session.add(new_user)
                print(f"Restored user: {u_data['username']}")
            else:
                existing.github_username = u_data['gh']
                print(f"User {u_data['username']} already exists, updated GitHub.")
        
        db.session.commit()

if __name__ == '__main__':
    restore()
