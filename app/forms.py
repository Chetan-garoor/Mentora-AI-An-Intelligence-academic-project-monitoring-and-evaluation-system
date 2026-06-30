from flask_wtf import FlaskForm
from flask_wtf.file import FileField, FileAllowed
from wtforms import StringField, PasswordField, SubmitField, SelectField, TextAreaField
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError, URL
from app.models import User
from flask_login import current_user

class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    role = SelectField('Role', choices=[
        ('HOD', 'HOD'),
        ('COORDINATOR', 'Coordinator'),
        ('FACULTY', 'Faculty'),
        ('STUDENT', 'Student')
    ], validators=[DataRequired()])
    submit = SubmitField('Login')

class StudentRegistrationForm(FlaskForm):
    username = StringField('Full Name', validators=[DataRequired(), Length(min=2, max=50)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    registration_number = StringField('Registration Number', validators=[DataRequired(), Length(min=3, max=20)])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register as Student')

    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user:
            raise ValidationError('That username is already taken. Please choose a different one.')

    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user:
            raise ValidationError('That email is already in use. Please choose a different one.')

    def validate_registration_number(self, registration_number):
        user = User.query.filter_by(registration_number=registration_number.data).first()
        if user:
            raise ValidationError('That registration number is already registered.')

class StaffRegistrationForm(FlaskForm):
    username = StringField('Full Name', validators=[DataRequired(), Length(min=2, max=50)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    role = SelectField('Role', choices=[
        ('HOD', 'HOD'),
        ('COORDINATOR', 'Coordinator'),
        ('FACULTY', 'Faculty')
    ], validators=[DataRequired()])
    department = StringField('Department', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register Staff')

    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user:
            raise ValidationError('That username is already taken. Please choose a different one.')

    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user:
            raise ValidationError('That email is already in use.')

class ProjectProposalForm(FlaskForm):
    title = StringField('Project Title', validators=[DataRequired(), Length(min=5, max=200)])
    description = TextAreaField('Description', validators=[DataRequired(), Length(min=20)])
    github_url = StringField('GitHub Repository URL', validators=[DataRequired(), URL()])
    submit = SubmitField('Submit Proposal')

class SettingsForm(FlaskForm):
    username = StringField('Full Name', validators=[DataRequired(), Length(min=2, max=50)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    registration_number = StringField('Registration Number (Students Only)')
    department = StringField('Department (Staff Only)')
    profile_photo = FileField('Profile Photo', validators=[
        FileAllowed(['jpg', 'jpeg', 'png', 'gif', 'webp'], 'Images only!')
    ])
    submit_profile = SubmitField('Update Profile')

    def validate_username(self, username):
        if username.data != current_user.username:
            user = User.query.filter_by(username=username.data).first()
            if user:
                raise ValidationError('That username is already taken. Please choose a different one.')

    def validate_email(self, email):
        if email.data != current_user.email:
            user = User.query.filter_by(email=email.data).first()
            if user:
                raise ValidationError('That email is already in use. Please choose a different one.')

    def validate_registration_number(self, registration_number):
        if registration_number.data and current_user.role == 'STUDENT':
            if registration_number.data != current_user.registration_number:
                user = User.query.filter_by(registration_number=registration_number.data).first()
                if user:
                    raise ValidationError('That registration number is already in use by another student.')

class ChangePasswordForm(FlaskForm):
    old_password = PasswordField('Current Password', validators=[DataRequired()])
    new_password = PasswordField('New Password', validators=[DataRequired(), Length(min=6)])
    confirm_password = PasswordField('Confirm New Password', validators=[DataRequired(), EqualTo('new_password')])
    submit_password = SubmitField('Change Password')

class ForgotPasswordForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    security_answer = StringField('Security Check: Enter your registered Full Name', validators=[DataRequired()])
    new_password = PasswordField('New Password', validators=[DataRequired(), Length(min=6)])
    confirm_password = PasswordField('Confirm New Password', validators=[DataRequired(), EqualTo('new_password')])
    submit = SubmitField('Reset Password')
