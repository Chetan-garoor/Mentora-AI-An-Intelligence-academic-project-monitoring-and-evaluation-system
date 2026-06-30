from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from app.models import WeeklyLog, Project, LogComment
from app import db
import os
from werkzeug.utils import secure_filename
from datetime import datetime

weekly = Blueprint('weekly', __name__)

@weekly.route('/weekly/upload', methods=['GET', 'POST'])
@login_required
def upload_log():
    if current_user.role != 'STUDENT' or not current_user.team_id:
        return redirect(url_for('main.dashboard'))
        
    project = Project.query.filter_by(team_id=current_user.team_id).first()
    if not project or project.status == 'Pending':
        flash('Project must be approved before uploading logs.', 'warning')
        return redirect(url_for('main.dashboard'))
        
    if request.method == 'POST':
        # Check if already uploaded this week (simplified)
        # In real logic, check week_number or timestamp difference
        
        remark = request.form.get('remarks')
        report = request.files.get('report')
        screenshot = request.files.get('screenshot')
        
        from flask import current_app
        import os
        
        report_path = None
        if report:
            report_name = secure_filename(report.filename)
            report_rel_path = os.path.join('reports', report_name)
            report_full_path = os.path.join(current_app.config['UPLOAD_FOLDER'], report_rel_path)
            report.save(report_full_path)
            report_path = report_rel_path.replace(os.sep, '/')
            
        ss_path = None
        if screenshot:
            ss_name = secure_filename(screenshot.filename)
            ss_rel_path = os.path.join('screenshots', ss_name)
            ss_full_path = os.path.join(current_app.config['UPLOAD_FOLDER'], ss_rel_path)
            screenshot.save(ss_full_path)
            ss_path = ss_rel_path.replace(os.sep, '/')
            
        new_log = WeeklyLog(
            week_number=(WeeklyLog.query.filter_by(project_id=project.id).count() + 1),
            report_path=report_path,
            screenshot_path=ss_path,
            remarks=remark,
            student_id=current_user.id,
            project_id=project.id
        )
        
        db.session.add(new_log)
        db.session.commit()
        flash('Weekly progress uploaded!', 'success')
        return redirect(url_for('main.dashboard'))
        
    return render_template('upload_weekly.html')

@weekly.route('/weekly/review/<int:log_id>', methods=['GET', 'POST'])
@login_required
def review_log(log_id):
    if current_user.role != 'FACULTY':
        return redirect(url_for('main.dashboard'))
        
    from app.models import WeeklyReview
    log = WeeklyLog.query.get_or_404(log_id)
    
    if request.method == 'POST':
        status = request.form.get('status')
        suggestions = request.form.get('suggestions')
        code_corrections = request.form.get('code_corrections')
        
        # Check if already reviewed
        review = WeeklyReview.query.filter_by(log_id=log.id).first()
        if not review:
            review = WeeklyReview(log_id=log.id, faculty_id=current_user.id)
            db.session.add(review)
            
        review.status = status
        review.suggestions = suggestions
        review.code_corrections = code_corrections
        review.reviewed_at = datetime.utcnow()
        
        db.session.commit()
        flash('Review submitted successfully.', 'success')
        return redirect(url_for('main.dashboard'))
        
    return render_template('review_weekly.html', log=log)

@weekly.route('/weekly/comment/<int:log_id>', methods=['POST'])
@login_required
def add_comment(log_id):
    content = request.form.get('content')
    if content:
        comment = LogComment(
            log_id=log_id,
            user_id=current_user.id,
            content=content
        )
        db.session.add(comment)
        db.session.commit()
        flash('Annotation added successfully.', 'success')
        
    if current_user.role == 'FACULTY':
        return redirect(url_for('weekly.review_log', log_id=log_id))
    return redirect(url_for('weekly.view_log', log_id=log_id))

@weekly.route('/weekly/view/<int:log_id>', methods=['GET'])
@login_required
def view_log(log_id):
    log = WeeklyLog.query.get_or_404(log_id)
    if current_user.role != 'STUDENT' and current_user.role != 'FACULTY':
         # Faculty might occasionally use student view for testing or link clicks
         pass
    
    if current_user.role == 'STUDENT' and log.project.team_id != current_user.team_id:
        return redirect(url_for('main.dashboard'))
        
    return render_template('view_weekly.html', log=log)

@weekly.route('/uploads/<path:filename>')
@login_required
def uploaded_file(filename):
    from flask import current_app, send_from_directory
    return send_from_directory(current_app.config['UPLOAD_FOLDER'], filename)
