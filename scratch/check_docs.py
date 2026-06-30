from app import create_app, db
from app.models import ProjectDocument

app = create_app()
with app.app_context():
    docs = ProjectDocument.query.all()
    print(f"Total documents: {len(docs)}")
    for doc in docs:
        print(f"ID: {doc.id}, Project ID: {doc.project_id}, File: {doc.filename}")
