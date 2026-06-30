import os
from werkzeug.utils import secure_filename
from flask import Blueprint, render_template, request, jsonify, redirect, url_for, flash, current_app, send_from_directory
from flask_login import login_required, current_user
from app.models import Project, Task, Team, User, ProjectMessage, ProjectDocument
from app import db, csrf

kanban = Blueprint('kanban', __name__)

@kanban.route('/kanban/<int:project_id>', methods=['GET'])
@login_required
def board(project_id):
    project = Project.query.get_or_404(project_id)
    
    # Check permissions
    if current_user.role == 'STUDENT' and current_user.team_id != project.team_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    tasks = Task.query.filter_by(project_id=project.id).order_by(Task.created_at.desc()).all()
    todo = [t for t in tasks if t.status == 'TODO']
    in_progress = [t for t in tasks if t.status == 'IN_PROGRESS']
    done = [t for t in tasks if t.status == 'DONE']
    
    # Get team members for assignment
    team_members = User.query.filter_by(team_id=project.team_id).all()
    
    # Get messages and documents
    messages = ProjectMessage.query.filter_by(project_id=project.id).order_by(ProjectMessage.created_at.asc()).all()
    documents = ProjectDocument.query.filter_by(project_id=project.id).order_by(ProjectDocument.uploaded_at.desc()).all()
    
    return render_template('kanban.html', project=project, todo=todo, in_progress=in_progress, done=done, team_members=team_members, messages=messages, documents=documents)

@kanban.route('/api/kanban/<int:project_id>/task', methods=['POST'])
@login_required
@csrf.exempt
def create_task(project_id):
    project = Project.query.get_or_404(project_id)
    if current_user.role == 'STUDENT' and current_user.team_id != project.team_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    data = request.get_json()
    if not data or not data.get('title'):
        return jsonify({'error': 'Title is required'}), 400
        
    new_task = Task(
        project_id=project.id,
        title=data['title'],
        description=data.get('description', ''),
        status=data.get('status', 'TODO'),
        assigned_to=data.get('assigned_to')
    )
    db.session.add(new_task)
    db.session.commit()
    
    return jsonify({
        'id': new_task.id,
        'title': new_task.title,
        'description': new_task.description,
        'status': new_task.status,
        'assigned_to': new_task.assigned_to
    }), 201

@kanban.route('/api/kanban/task/<int:task_id>/update', methods=['POST'])
@login_required
@csrf.exempt
def update_task_status(task_id):
    task = Task.query.get_or_404(task_id)
    project = Project.query.get(task.project_id)
    
    if current_user.role == 'STUDENT' and current_user.team_id != project.team_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    data = request.get_json()
    if 'status' in data:
        task.status = data['status']
    if 'assigned_to' in data:
        task.assigned_to = data['assigned_to'] if data['assigned_to'] else None
        
    db.session.commit()
    return jsonify({'success': True}), 200

@kanban.route('/api/kanban/task/<int:task_id>/delete', methods=['DELETE'])
@login_required
@csrf.exempt
def delete_task(task_id):
    task = Task.query.get_or_404(task_id)
    project = Project.query.get(task.project_id)
    
    if current_user.role == 'STUDENT' and current_user.team_id != project.team_id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    db.session.delete(task)
    db.session.commit()
    return jsonify({'success': True}), 200

@kanban.route('/kanban/<int:project_id>/message', methods=['POST'])
@login_required
def post_message(project_id):
    project = Project.query.get_or_404(project_id)
    message_text = request.form.get('message')
    
    if message_text:
        msg = ProjectMessage(project_id=project.id, user_id=current_user.id, message=message_text)
        db.session.add(msg)
        db.session.commit()
        
    return redirect(url_for('kanban.board', project_id=project.id))

@kanban.route('/kanban/<int:project_id>/document', methods=['POST'])
@login_required
def upload_document(project_id):
    project = Project.query.get_or_404(project_id)
    
    if 'document' not in request.files:
        flash('No file uploaded', 'danger')
        return redirect(url_for('kanban.board', project_id=project.id))
        
    file = request.files['document']
    if file.filename == '':
        flash('No selected file', 'danger')
        return redirect(url_for('kanban.board', project_id=project.id))
        
    if file:
        filename = secure_filename(file.filename)
        doc_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], 'documents', str(project.id))
        os.makedirs(doc_dir, exist_ok=True)
        file_path = os.path.join(doc_dir, filename)
        
        file.save(file_path)
        
        doc = ProjectDocument(
            project_id=project.id,
            uploader_id=current_user.id,
            filename=filename,
            file_path=os.path.join('documents', str(project.id), filename)
        )
        db.session.add(doc)
        db.session.commit()
        flash('Document uploaded successfully!', 'success')
        
    return redirect(url_for('kanban.board', project_id=project.id))

@kanban.route('/kanban/document/download/<int:doc_id>')
@login_required
def download_document(doc_id):
    doc = ProjectDocument.query.get_or_404(doc_id)
    return send_from_directory(current_app.config['UPLOAD_FOLDER'], doc.file_path, as_attachment=True)

