from flask import Blueprint, render_template, redirect, url_for, flash, request, send_from_directory, current_app
from flask_login import login_user, logout_user, current_user, login_required
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from app.models import User, Team
from app import db
from app.forms import LoginForm, StudentRegistrationForm, StaffRegistrationForm, SettingsForm, ChangePasswordForm, ForgotPasswordForm
from flask import session
import os
import uuid

auth = Blueprint('auth', __name__)

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
    
    form = LoginForm()
    failed_attempts = session.get('failed_attempts', 0)
    
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data, role=form.role.data).first()
        if user and check_password_hash(user.password, form.password.data):
            session.pop('failed_attempts', None)
            login_user(user)
            return redirect(url_for('main.dashboard'))
        else:
            failed_attempts += 1
            session['failed_attempts'] = failed_attempts
            flash(f'Login unsuccessful for {form.role.data}. Please check email and password.', 'danger')
            
    return render_template('login.html', form=form, failed_attempts=failed_attempts)

@auth.route('/register')
def register_select():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
    return render_template('register.html')

@auth.route('/register/student', methods=['GET', 'POST'])
def register_student():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
    
    form = StudentRegistrationForm()
    if form.validate_on_submit():
        hashed_pw = generate_password_hash(form.password.data)
        new_user = User(
            username=form.username.data, 
            email=form.email.data, 
            password=hashed_pw, 
            role='STUDENT',
            registration_number=form.registration_number.data
        )
        db.session.add(new_user)
        db.session.commit()
        flash('Student account created! You can now login.', 'success')
        return redirect(url_for('auth.login'))
        
    return render_template('register_student.html', form=form)

@auth.route('/register/staff', methods=['GET', 'POST'])
def register_staff():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
    
    form = StaffRegistrationForm()
    
    # Handle pre-selected role from query parameters
    requested_role = request.args.get('role')
    if requested_role in ['FACULTY', 'COORDINATOR', 'HOD'] and request.method == 'GET':
        form.role.data = requested_role

    if form.validate_on_submit():
        hashed_pw = generate_password_hash(form.password.data)
        new_user = User(
            username=form.username.data, 
            email=form.email.data, 
            password=hashed_pw, 
            role=form.role.data,
            department=form.department.data
        )
        db.session.add(new_user)
        db.session.commit()
        flash(f'{form.role.data} account created! You can now login.', 'success')
        return redirect(url_for('auth.login'))
        
    return render_template('register_staff.html', form=form)

@auth.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('auth.login'))

@auth.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    profile_form = SettingsForm()
    password_form = ChangePasswordForm()
    
    if profile_form.submit_profile.data and profile_form.validate_on_submit():
        current_user.username = profile_form.username.data
        current_user.email = profile_form.email.data
        if current_user.role == 'STUDENT':
            current_user.registration_number = profile_form.registration_number.data
        else:
            current_user.department = profile_form.department.data
        
        # Handle profile photo upload
        photo = profile_form.profile_photo.data
        if photo and hasattr(photo, 'filename') and photo.filename:
            filename = secure_filename(photo.filename)
            # Generate unique filename to avoid conflicts
            ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else 'png'
            unique_filename = f"profile_{current_user.id}_{uuid.uuid4().hex[:8]}.{ext}"
            upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], 'profile_photos')
            filepath = os.path.join(upload_dir, unique_filename)
            
            # Delete old photo if it exists
            if current_user.profile_photo:
                old_path = os.path.join(upload_dir, current_user.profile_photo)
                if os.path.exists(old_path):
                    os.remove(old_path)
            
            photo.save(filepath)
            current_user.profile_photo = unique_filename
        
        db.session.commit()
        flash('Your profile has been updated!', 'success')
        return redirect(url_for('auth.settings'))
        
    elif password_form.submit_password.data and password_form.validate_on_submit():
        if check_password_hash(current_user.password, password_form.old_password.data):
            current_user.password = generate_password_hash(password_form.new_password.data)
            db.session.commit()
            flash('Your password has been updated!', 'success')
            return redirect(url_for('auth.settings'))
        else:
            flash('Incorrect current password.', 'danger')
            
    elif request.method == 'GET':
        profile_form.username.data = current_user.username
        profile_form.email.data = current_user.email
        profile_form.registration_number.data = current_user.registration_number
        profile_form.department.data = current_user.department
        
    return render_template('settings.html', profile_form=profile_form, password_form=password_form)

@auth.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
        
    form = ForgotPasswordForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        # Security check: verify the full name matches the email on record
        if user and user.username.lower().strip() == form.security_answer.data.lower().strip():
            user.password = generate_password_hash(form.new_password.data)
            db.session.commit()
            session.pop('failed_attempts', None)
            flash('Your password has been successfully reset! You can now log in.', 'success')
            return redirect(url_for('auth.login'))
        else:
            flash('Invalid email or security answer. We could not verify your identity.', 'danger')
            
    return render_template('forgot_password.html', form=form)

@auth.route('/uploads/profile_photos/<filename>')
def serve_profile_photo(filename):
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], 'profile_photos')
    return send_from_directory(upload_dir, filename)
