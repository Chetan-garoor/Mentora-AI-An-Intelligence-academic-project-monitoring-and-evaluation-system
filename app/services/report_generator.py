from datetime import datetime
from app.models import Project, User, AIEvaluation, GithubActivity, WeeklyLog
from app.services.code_scanner import CodeScanner

class ReportGenerator:
    @staticmethod
    def generate_project_report(project_id):
        project = Project.query.get(project_id)
        if not project:
            return None
            
        repo_analysis = CodeScanner.analyze_repository(project.github_url)
        
        report_data = {
            'project_title': project.title,
            'team_name': project.team.name,
            'github_url': project.github_url,
            'description': project.description,
            'status': project.status,
            'generated_at': datetime.utcnow(),
            'originality_score': repo_analysis['originality_score'],
            'code_risk_level': repo_analysis['risk_level'],
            'code_insights': repo_analysis['insights'],
            'students': []
        }
        
        for student in project.team.members:
            evaluation = AIEvaluation.query.filter_by(project_id=project_id, student_id=student.id).order_by(AIEvaluation.last_updated.desc()).first()
            latest_activity = GithubActivity.query.filter_by(student_id=student.id).order_by(GithubActivity.date_recorded.desc()).first()
            logs = WeeklyLog.query.filter_by(project_id=project_id, student_id=student.id).all()
            
            student_stats = {
                'username': student.username,
                'reg_no': student.registration_number,
                'role': 'Team Lead' if student.id == project.team.team_lead_id else 'Member',
                'contribution_score': evaluation.contribution_score if evaluation else 0,
                'behaviour_tags': evaluation.behaviour_tags if evaluation else 'Good Contributor',
                'risk_level': evaluation.risk_level if evaluation else 'ON_TRACK',
                'total_commits': latest_activity.commits if latest_activity else 0,
                'total_additions': latest_activity.additions if latest_activity else 0,
                'total_deletions': latest_activity.deletions if latest_activity else 0,
                'total_logs': len(logs),
                'latest_feedback': logs[-1].review.suggestions if logs and logs[-1].review else 'No feedback yet'
            }
            report_data['students'].append(student_stats)
            
        return report_data
