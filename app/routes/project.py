from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from app.models import Project, Team, User, Notification
from app.services.github_service import GitHubService
from app import db

project = Blueprint('project', __name__)

@project.route('/team/create', methods=['GET', 'POST'])
@login_required
def create_team():
    if current_user.role != 'STUDENT':
        return redirect(url_for('main.dashboard'))
    
    if current_user.team_id:
        flash('You are already in a team.', 'info')
        return redirect(url_for('main.dashboard'))
        
    if request.method == 'POST':
        name = request.form.get('name')
        new_team = Team(name=name, team_lead_id=current_user.id)
        db.session.add(new_team)
        db.session.flush()
        
        current_user.team_id = new_team.id
        db.session.commit()
        flash('Team created successfully! Add members below.', 'success')
        return redirect(url_for('project.manage_team'))
        
    return render_template('create_team.html')

@project.route('/team/manage', methods=['GET', 'POST'])
@login_required
def manage_team():
    if current_user.role != 'STUDENT' or not current_user.team_id:
        return redirect(url_for('main.dashboard'))
        
    team = Team.query.get(current_user.team_id)
    
    if request.method == 'POST':
        if team.is_frozen:
            flash('Team is frozen after approval.', 'danger')
            return redirect(url_for('project.manage_team'))
            
        action = request.form.get('action')
        if action == 'add_member':
            if len(team.members) >= 4:
                flash('Team is full (Max 4 members).', 'warning')
            else:
                email = request.form.get('email')
                member = User.query.filter_by(email=email, role='STUDENT').first()
                if member:
                    if member.team_id:
                        flash('User is already in a team.', 'warning')
                    else:
                        member.team_id = team.id
                        db.session.commit()
                        flash(f'{member.username} added to team.', 'success')
                else:
                    flash('Student not found.', 'danger')
                    
        elif action == 'set_lead':
            if current_user.id != team.team_lead_id:
                flash('Only current lead can change team lead.', 'danger')
            else:
                new_lead_id = request.form.get('member_id')
                team.team_lead_id = new_lead_id
                db.session.commit()
                flash('Team lead updated.', 'info')
                
    return render_template('manage_team.html', team=team)

@project.route('/project/submit', methods=['GET', 'POST'])
@login_required
def submit_proposal():
    if current_user.role != 'STUDENT' or not current_user.team_id:
        flash('Join a team before submitting a proposal.', 'warning')
        return redirect(url_for('main.dashboard'))
    
    team = Team.query.get(current_user.team_id)
    if current_user.id != team.team_lead_id:
        flash('Only team lead can submit proposal.', 'danger')
        return redirect(url_for('main.dashboard'))
        
    if request.method == 'POST':
        title = request.form.get('title')
        description = request.form.get('description')
        github_url = request.form.get('github_url')
        
        existing_project = Project.query.filter_by(team_id=team.id).first()
        if existing_project:
            existing_project.title = title
            existing_project.description = description
            existing_project.github_url = github_url
            existing_project.status = 'Pending'
        else:
            new_project = Project(
                title=title,
                description=description,
                github_url=github_url,
                team_id=team.id
            )
            db.session.add(new_project)
            
        # Update team members' GitHub usernames
        for member in team.members:
            gh_user = request.form.get(f'gh_user_{member.id}')
            if gh_user:
                member.github_username = gh_user
                
        db.session.commit()
        flash('Project proposal submitted and team GitHub usernames updated!', 'success')
        return redirect(url_for('main.dashboard'))
        
    return render_template('submit_proposal.html', team=team)

@project.route('/coordinator/projects')
@login_required
def coordinator_dashboard():
    if current_user.role != 'COORDINATOR':
        return redirect(url_for('main.dashboard'))
    projects = Project.query.all()
    return render_template('coordinator_dashboard.html', projects=projects)

@project.route('/project/action/<int:project_id>', methods=['POST'])
@login_required
def coordinator_action(project_id):
    if current_user.role != 'COORDINATOR':
        return redirect(url_for('main.dashboard'))
        
    p = Project.query.get_or_404(project_id)
    action = request.form.get('action')
    
    if action == 'approve':
        p.status = 'Approved'
        p.team.is_frozen = True # Freeze team after approval
        p.coordinator_id = current_user.id
        flash('Project approved and team frozen.', 'success')
    elif action == 'reject':
        p.status = 'Rejected'
        flash('Project rejected.', 'danger')
    elif action == 'modify':
        p.status = 'Modification Requested'
        flash('Modification requested from student.', 'info')
        
    db.session.commit()
    return redirect(url_for('project.coordinator_dashboard'))

@project.route('/coordinator/assign_guide', methods=['POST'])
@login_required
def assign_guide():
    if current_user.role != 'COORDINATOR':
        return redirect(url_for('main.dashboard'))
        
    team_id = request.form.get('team_id')
    faculty_id = request.form.get('faculty_id')
    
    # Remove existing assignment if any
    from app.models import FacultyAssignment
    FacultyAssignment.query.filter_by(team_id=team_id).delete()
    
    new_assignment = FacultyAssignment(faculty_id=faculty_id, team_id=team_id)
    db.session.add(new_assignment)
    db.session.commit()
    flash('Faculty guide assigned successfully.', 'success')
    return redirect(url_for('project.coordinator_dashboard'))

@project.route('/hod/final_approve/<int:project_id>', methods=['POST'])
@login_required
def hod_final_approve(project_id):
    if current_user.role != 'HOD':
        return redirect(url_for('main.dashboard'))
        
    p = Project.query.get_or_404(project_id)
    p.status = 'Final Approved'
    db.session.commit()
    flash('Project Finalized! It is now recorded in the department records.', 'success')
    return redirect(url_for('main.dashboard'))

@project.route('/project/report/<int:project_id>')
@login_required
def view_report(project_id):
    from app.services.report_generator import ReportGenerator
    report_data = ReportGenerator.generate_project_report(project_id)
    if not report_data:
        flash('Report not found.', 'danger')
        return redirect(url_for('main.dashboard'))
    return render_template('report.html', report=report_data)

@project.route('/project/sync/<int:project_id>')
@login_required
def sync_github(project_id):
    p = Project.query.get_or_404(project_id)
    if current_user.team_id != p.team_id:
        flash('Unauthorized.', 'danger')
        return redirect(url_for('main.dashboard'))
        
    gh = GitHubService()
    result = gh.fetch_repo_activity(project_id)
    
    # Trigger AI Analysis immediately so the score updates in real-time
    from app.services.ai_analyzer import AIAnalyzer
    AIAnalyzer.analyze_student_contribution(current_user.id, project_id)
    
    if result == True:
        flash('GitHub activity synced successfully!', 'success')
    elif result == "Processing":
        flash('GitHub is still calculating line counts (additions/deletions), but commit counts have been updated.', 'info')
    else:
        flash('Live sync failed. Please check your GitHub URL and Personal Access Token.', 'danger')
        
    return redirect(url_for('main.dashboard'))

@project.route('/project/commits/<int:project_id>')
@login_required
def get_commits(project_id):
    from flask import jsonify
    p = Project.query.get_or_404(project_id)
    if current_user.team_id != p.team_id and current_user.role not in ['FACULTY', 'HOD', 'COORDINATOR']:
        return jsonify([])
        
    gh = GitHubService()
    commits = gh.get_recent_commits(project_id)
    return jsonify(commits)

@project.route('/project/broadcast/<int:team_id>', methods=['POST'])
@login_required
def broadcast_notification(team_id):
    team = Team.query.get_or_404(team_id)
    message = request.form.get('message')
    
    if not message:
        flash('Message cannot be empty.', 'warning')
        return redirect(request.referrer or url_for('main.dashboard'))
        
    # Authorization Check: ONLY Faculty can send messages to their assigned team
    authorized = False
    if current_user.role == 'FACULTY':
        from app.models import FacultyAssignment
        assignment = FacultyAssignment.query.filter_by(faculty_id=current_user.id, team_id=team_id).first()
        if assignment:
            authorized = True
            
    if not authorized:
        flash('Access Restricted: Only the assigned Faculty Mentor can broadcast to this team.', 'danger')
        return redirect(url_for('main.dashboard'))
        
    # Send notifications to all team members
    for member in team.members:
        notif = Notification(
            user_id=member.id,
            message=f"[{current_user.username}]: {message}"
        )
        db.session.add(notif)
        
    db.session.commit()
    flash(f'Broadcast sent to {team.name} successfully!', 'success')
    return redirect(request.referrer or url_for('main.dashboard'))

@project.route('/project/<int:project_id>/peer_evaluation', methods=['GET', 'POST'])
@login_required
def peer_evaluation(project_id):
    if current_user.role != 'STUDENT':
        return redirect(url_for('main.dashboard'))
        
    project = Project.query.get_or_404(project_id)
    if project.team_id != current_user.team_id:
        flash('You can only evaluate your own team members.', 'danger')
        return redirect(url_for('main.dashboard'))
        
    from app.models import PeerEvaluation, WeeklyLog
    teammates = [m for m in project.team.members if m.id != current_user.id]
    
    # Calculate current week (logs submitted + 1)
    current_week = WeeklyLog.query.filter_by(project_id=project.id).count() + 1
    
    if request.method == 'POST':
        submitted_evals = 0
        for teammate in teammates:
            score = request.form.get(f'score_{teammate.id}')
            comments = request.form.get(f'feedback_{teammate.id}')
            
            if not score:
                continue
                
            # Check if already evaluated for THIS week
            existing = PeerEvaluation.query.filter_by(
                evaluator_id=current_user.id,
                evaluatee_id=teammate.id,
                project_id=project.id,
                week_number=current_week
            ).first()
            
            if existing:
                existing.score = score
                existing.feedback = comments
            else:
                new_eval = PeerEvaluation(
                    evaluator_id=current_user.id,
                    evaluatee_id=teammate.id,
                    project_id=project.id,
                    week_number=current_week,
                    score=score,
                    feedback=comments
                )
                db.session.add(new_eval)
            submitted_evals += 1
            
        if submitted_evals > 0:
            db.session.commit()
            flash(f'Evaluations for Week {current_week} submitted successfully.', 'success')
            return redirect(url_for('main.dashboard'))
        else:
            flash('Please provide scores for your teammates.', 'warning')
        
    my_evals = PeerEvaluation.query.filter_by(
        evaluator_id=current_user.id, 
        project_id=project.id,
        week_number=current_week
    ).all()
    eval_map = {e.evaluatee_id: e for e in my_evals}
        
    return render_template('peer_evaluation.html', project=project, teammates=teammates, eval_map=eval_map, current_week=current_week)
