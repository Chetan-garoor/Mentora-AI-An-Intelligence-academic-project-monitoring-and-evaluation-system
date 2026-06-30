from app import create_app, db
from app.models import User, Team, Project, FacultyAssignment, WeeklyLog, WeeklyReview, GithubActivity, AIEvaluation
from werkzeug.security import generate_password_hash
from datetime import datetime, timedelta

def seed_db():
    app = create_app()
    with app.app_context():
        # Clean database
        db.drop_all()
        db.create_all()

        print("Seeding database with 4-tier RBAC data...")

        # 1. Create HOD
        hod = User(
            username="Dr. Alan Turing",
            email="hod@cs.university.edu",
            password=generate_password_hash("password123"),
            role="HOD",
            department="Computer Science"
        )
        db.session.add(hod)

        # 2. Create Coordinator
        coord = User(
            username="Dr. Grace Hopper",
            email="coordinator@cs.university.edu",
            password=generate_password_hash("password123"),
            role="COORDINATOR",
            department="Computer Science"
        )
        db.session.add(coord)

        # 3. Create Faculty
        faculty = User(
            username="Dr. John Smith",
            email="smith@university.edu",
            password=generate_password_hash("password123"),
            role="FACULTY",
            department="Computer Science"
        )
        db.session.add(faculty)

        # 4. Create Students and Team
        team = Team(name="Project Alpha")
        db.session.add(team)
        db.session.flush()

        s1 = User(
            username="Alice Lead",
            email="alice@student.com",
            password=generate_password_hash("password123"),
            role="STUDENT",
            registration_number="CS001",
            team_id=team.id
        )
        s2 = User(
            username="Bob Member",
            email="bob@student.com",
            password=generate_password_hash("password123"),
            role="STUDENT",
            registration_number="CS002",
            team_id=team.id
        )
        db.session.add_all([s1, s2])
        db.session.flush()
        
        team.team_lead_id = s1.id # Alice is lead

        # 5. Create Project
        project = Project(
            title="AI Based Smart Agriculture",
            description="Using CNN to detect crop diseases and predict yield.",
            github_url="https://github.com/alice/smart_agri",
            status="Approved",
            team_id=team.id,
            coordinator_id=coord.id
        )
        db.session.add(project)
        db.session.flush()

        # 6. Assign Faculty
        assignment = FacultyAssignment(faculty_id=faculty.id, team_id=team.id)
        db.session.add(assignment)

        # 7. Add Weekly Log & Review
        log = WeeklyLog(
            week_number=1,
            report_path="reports/week1.pdf",
            remarks="Completed literature survey and dataset collection.",
            student_id=s1.id,
            project_id=project.id,
            timestamp=datetime.utcnow() - timedelta(days=7)
        )
        db.session.add(log)
        db.session.flush()

        review = WeeklyReview(
            log_id=log.id,
            faculty_id=faculty.id,
            status="Approved",
            suggestions="Great start. Focus on the model architecture next.",
            code_corrections="Ensure the input data is normalized [0, 1]."
        )
        db.session.add(review)

        # 8. Add GitHub Activity (Multi-day for Charts)
        # Alice (Lead) - 7 day history
        for i in range(7):
            day_act = GithubActivity(
                student_id=s1.id,
                commits=5 + (i % 3),
                additions=100 + (i * 20),
                deletions=20 + (i * 5),
                date_recorded=datetime.utcnow() - timedelta(days=6-i)
            )
            db.session.add(day_act)

        # Bob (Member) - Basic activity
        bob_act = GithubActivity(
            student_id=s2.id,
            commits=4,
            additions=450,
            deletions=100,
            date_recorded=datetime.utcnow()
        )
        db.session.add(bob_act)
        
        # 9. AI Evaluations
        eval_alice = AIEvaluation(
            project_id=project.id,
            student_id=s1.id,
            contribution_score=85.0,
            behaviour_tags="Lead Contributor",
            risk_level="ON_TRACK"
        )
        eval_bob = AIEvaluation(
            project_id=project.id,
            student_id=s2.id,
            contribution_score=15.0,
            behaviour_tags="Minor Contributor",
            risk_level="AT_RISK"
        )
        db.session.add_all([eval_alice, eval_bob])

        db.session.commit()
        print("\nDatabase seeded successfully!")
        print("-" * 30)
        print("HOD: hod@cs.university.edu / password123")
        print("Coordinator: coordinator@cs.university.edu / password123")
        print("Faculty: smith@university.edu / password123")
        print("Student (Lead): alice@student.com / password123")
        print("-" * 30)

if __name__ == "__main__":
    seed_db()
