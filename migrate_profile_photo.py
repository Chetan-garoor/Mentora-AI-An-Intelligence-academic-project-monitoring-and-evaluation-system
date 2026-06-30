"""
Database migration script to add profile_photo column to the user table.
Run this script once to update the existing database schema.
"""
import os
from app import create_app, db
from sqlalchemy import text

app = create_app()
with app.app_context():
    try:
        db.session.execute(text('ALTER TABLE user ADD COLUMN profile_photo VARCHAR(200)'))
        db.session.commit()
        print("Migration successful: added 'profile_photo' column to user table.")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("Column 'profile_photo' already exists. No changes needed.")
        else:
            print(f"Migration error: {e}")
