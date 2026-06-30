from datetime import datetime
from flask_login import UserMixin
from app import db, login_manager

@login_manager.user_loader
def load_user(user_id):
    try:
        # Handle legacy prefixed IDs if they still exist in cookies
        if isinstance(user_id, str):
            if user_id.startswith('student_'):
                user_id = user_id.replace('student_', '')
            elif user_id.startswith('faculty_'):
                user_id = user_id.replace('faculty_', '')
        return User.query.get(int(user_id))
    except (ValueError, TypeError):
        return None

class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(20), nullable=False) # 'HOD', 'COORDINATOR', 'FACULTY', 'STUDENT'
    
    # Student specific
    registration_number = db.Column(db.String(20), unique=True, nullable=True)
    github_username = db.Column(db.String(100), unique=True, nullable=True)
    team_id = db.Column(db.Integer, db.ForeignKey('team.id'), nullable=True)
    
    # Profile photo
    profile_photo = db.Column(db.String(200), nullable=True)
    
    # Faculty / Dept specific
    department = db.Column(db.String(100), nullable=True)
    
    # Relationships
    weekly_logs = db.relationship('WeeklyLog', backref='student', lazy=True)
    reviews_given = db.relationship('WeeklyReview', backref='faculty', lazy=True)
    notifications = db.relationship('Notification', backref='user', lazy=True)

    def get_role(self):
        return self.role.lower()

class Team(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    team_lead_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    is_frozen = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    members = db.relationship('User', backref='team', foreign_keys=[User.team_id], lazy=True)
    project = db.relationship('Project', backref='team', uselist=False)
    assignments = db.relationship('FacultyAssignment', backref='team', lazy=True)

class Project(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    github_url = db.Column(db.String(200), nullable=False)
    status = db.Column(db.String(20), default='Pending') # Pending, Modification Requested, Approved, Final Approved
    team_id = db.Column(db.Integer, db.ForeignKey('team.id'), nullable=False)
    coordinator_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    
    weekly_logs = db.relationship('WeeklyLog', backref='project', lazy=True)
    evaluations = db.relationship('AIEvaluation', backref='project', lazy=True)
    tasks = db.relationship('Task', backref='project', lazy=True)
    peer_evaluations = db.relationship('PeerEvaluation', backref='project', lazy=True)
    messages = db.relationship('ProjectMessage', backref='project', lazy=True, cascade="all, delete-orphan")
    documents = db.relationship('ProjectDocument', backref='project', lazy=True, cascade="all, delete-orphan")

class PeerEvaluation(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'), nullable=False)
    evaluator_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    evaluatee_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    week_number = db.Column(db.Integer, nullable=False)
    score = db.Column(db.Integer, nullable=False) # 1 to 5
    feedback = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    evaluator = db.relationship('User', foreign_keys=[evaluator_id])
    evaluatee = db.relationship('User', foreign_keys=[evaluatee_id])

class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), default='TODO') # TODO, IN_PROGRESS, DONE
    assigned_to = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    assignee = db.relationship('User', foreign_keys=[assigned_to])

class FacultyAssignment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    faculty_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    team_id = db.Column(db.Integer, db.ForeignKey('team.id'), nullable=False)
    assigned_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Add relationship to access faculty details
    faculty = db.relationship('User', foreign_keys=[faculty_id])

class WeeklyLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    week_number = db.Column(db.Integer, nullable=False)
    report_path = db.Column(db.String(200), nullable=False)
    screenshot_path = db.Column(db.String(200), nullable=True)
    remarks = db.Column(db.Text, nullable=True)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    is_late = db.Column(db.Boolean, default=False)
    student_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'), nullable=False)
    review = db.relationship('WeeklyReview', backref='log', uselist=False, lazy=True)
    comments = db.relationship('LogComment', backref='log', lazy=True, cascade="all, delete-orphan")

class LogComment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    log_id = db.Column(db.Integer, db.ForeignKey('weekly_log.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', foreign_keys=[user_id])

class WeeklyReview(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    log_id = db.Column(db.Integer, db.ForeignKey('weekly_log.id'), nullable=False)
    faculty_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    status = db.Column(db.String(20), nullable=False) # Approved, Waiting, Rejected
    suggestions = db.Column(db.Text)
    code_corrections = db.Column(db.Text)
    reviewed_at = db.Column(db.DateTime, default=datetime.utcnow)

class GithubActivity(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    commits = db.Column(db.Integer, default=0)
    additions = db.Column(db.Integer, default=0)
    deletions = db.Column(db.Integer, default=0)
    consistency_score = db.Column(db.Float, default=0.0) # Calculated
    last_activity = db.Column(db.DateTime, nullable=True)
    date_recorded = db.Column(db.DateTime, default=datetime.utcnow)

class AIEvaluation(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'), nullable=False)
    student_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    contribution_score = db.Column(db.Float, default=0.0)
    behaviour_tags = db.Column(db.String(200)) # "Free Rider", "Inactive", "Last Minute"
    risk_level = db.Column(db.String(50)) # "ON_TRACK", "AT_RISK"
    recommendation = db.Column(db.Text)
    last_updated = db.Column(db.DateTime, default=datetime.utcnow)

class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    message = db.Column(db.Text, nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class ProjectMessage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', foreign_keys=[user_id])

class ProjectDocument(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'), nullable=False)
    uploader_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    filename = db.Column(db.String(255), nullable=False)
    file_path = db.Column(db.String(500), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    uploader = db.relationship('User', foreign_keys=[uploader_id])
