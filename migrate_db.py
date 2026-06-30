import os
from app import create_app, db
from sqlalchemy import text

app = create_app()
with app.app_context():
    try:
        db.session.execute(text('ALTER TABLE user ADD COLUMN github_username VARCHAR(100)'))
        db.session.commit()
        print("Database migration successful: added 'github_username' column.")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("Column 'github_username' already exists.")
        else:
            print(f"Migration error: {e}")
