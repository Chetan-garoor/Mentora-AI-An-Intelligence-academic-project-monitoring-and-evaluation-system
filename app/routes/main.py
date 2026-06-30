from flask import Blueprint, render_template, redirect, url_for, jsonify
from flask_login import login_required, current_user
from app.models import Project, Team, User, AIEvaluation, GithubActivity, Notification
from app import db

main = Blueprint('main', __name__)

@main.route('/notifications/mark_read', methods=['POST'])
@login_required
def mark_notifications_read():
    unread = Notification.query.filter_by(user_id=current_user.id, is_read=False).all()
    for notif in unread:
        notif.is_read = True
    db.session.commit()
    return jsonify({'status': 'success'})

@main.route('/')
def index():
    return render_template('index.html')

@main.route('/dashboard')
@login_required
def dashboard():
    role = current_user.role
    if role == 'STUDENT':
        project = Project.query.filter_by(team_id=current_user.team_id).first()
        evaluation = None
        activity = []
        peer_insights = []
        if project:
            from app.models import PeerEvaluation
            evaluation = AIEvaluation.query.filter_by(project_id=project.id, student_id=current_user.id).first()
            activity = GithubActivity.query.filter_by(student_id=current_user.id).order_by(GithubActivity.date_recorded.desc()).limit(7).all()
            peer_insights = PeerEvaluation.query.filter_by(evaluatee_id=current_user.id).order_by(PeerEvaluation.week_number.desc()).all()
            
        from datetime import timedelta
        ist_sync_time = None
        if evaluation and evaluation.last_updated:
            ist_sync_time = (evaluation.last_updated + timedelta(hours=5, minutes=30)).strftime('%H:%M')

        return render_template('student_dashboard.html', 
                             project=project, 
                             evaluation=evaluation, 
                             activity=activity,
                             peer_insights=peer_insights,
                             ist_sync_time=ist_sync_time)
    
    elif role == 'FACULTY':
        from app.models import FacultyAssignment
        assignments = FacultyAssignment.query.filter_by(faculty_id=current_user.id).all()
        team_ids = [a.team_id for a in assignments]
        projects = Project.query.filter(Project.team_id.in_(team_ids)).all() if team_ids else []
        return render_template('faculty_dashboard.html', projects=projects)
        
    elif role == 'COORDINATOR':
        projects = Project.query.all()
        from app.models import User
        faculty_list = User.query.filter_by(role='FACULTY').all()
        return render_template('coordinator_dashboard.html', projects=projects, faculty_list=faculty_list)
        
    elif role == 'HOD':
        projects = Project.query.all()
        return render_template('hod_dashboard.html', projects=projects)
        
    return redirect(url_for('main.index'))
