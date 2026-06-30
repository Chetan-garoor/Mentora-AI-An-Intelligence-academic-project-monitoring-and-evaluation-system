from app import create_app, db

app = create_app()

# Ensure the database tables are created on launch if they don't exist
with app.app_context():
    db.create_all()
