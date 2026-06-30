from flask import Blueprint, request, jsonify

chatbot = Blueprint('chatbot', __name__)

# Basic knowledge base based on the app's workflow and README
KNOWLEDGE_BASE = {
    'roles': 'The system has 4 roles: HOD, Coordinator, Faculty Guide, and Student.',
    'hod': 'The Head of Department (HOD) provides strategic oversight and finalizes projects.',
    'coordinator': 'The Project Coordinator vets proposals and matches mentor-teams.',
    'faculty': 'The Faculty Guide monitors weekly progress and gives code-review feedback.',
    'student': 'Students collaborate on development and submit weekly logs. Their performance is tracked automatically.',
    'ai': 'The AI Contribution Intelligence analyzes GitHub commits, code volume, and submission consistency. It flags Free Riders automatically using Isolation Forest Anomaly Detection.',
    'report': 'You can generate a professional, signature-ready PDF report with full contribution breakdowns by clicking "Download Report" on the project page.',
    'github': 'The system integrates with GitHub to sync activity. Make sure your repository URL is correct in your project proposal.',
    'proposal': 'Students construct a team, and the Team Lead can submit a project proposal for the Coordinator to review.',
    'login': 'Use your registered email and password to login. Ensure you select the correct role from the dropdown.',
    'frozen': 'Once a project is approved, the team becomes frozen and no new members can be added.',
    'risk': 'The AI system calculates a risk level: ON_TRACK or AT_RISK, depending on your contribution score and inactivity over 14 days.'
}

def mock_ai_response(user_message):
    msg = user_message.lower()
    
    # Simple NLP rules
    if 'role' in msg or 'who' in msg:
        if 'hod' in msg: return KNOWLEDGE_BASE['hod']
        if 'coordinator' in msg: return KNOWLEDGE_BASE['coordinator']
        if 'faculty' in msg or 'guide' in msg or 'mentor' in msg: return KNOWLEDGE_BASE['faculty']
        if 'student' in msg: return KNOWLEDGE_BASE['student']
        return KNOWLEDGE_BASE['roles']
        
    if 'ai' in msg or 'intelligence' in msg or 'score' in msg or 'free rider' in msg:
        return KNOWLEDGE_BASE['ai']
        
    if 'report' in msg or 'pdf' in msg or 'download' in msg:
        return KNOWLEDGE_BASE['report']
        
    if 'github' in msg or 'commit' in msg or 'repo' in msg:
        return KNOWLEDGE_BASE['github']
        
    if 'proposal' in msg or 'create project' in msg:
        return KNOWLEDGE_BASE['proposal']
        
    if 'login' in msg or 'sign in' in msg or 'register' in msg:
        return KNOWLEDGE_BASE['login']
        
    if 'frozen' in msg or 'add member' in msg or 'team' in msg:
        return KNOWLEDGE_BASE['frozen']
        
    if 'risk' in msg or 'at risk' in msg or 'inactive' in msg:
        return KNOWLEDGE_BASE['risk']
        
    if 'hello' in msg or 'hi' in msg or 'hey' in msg:
        return "Hello! I am your AI Assistant. How can I help you with the Academic Project Monitor today?"
        
    if 'how' in msg and ('work' in msg or 'do' in msg):
        return "I am an AI support agent built into this Academic Project Monitoring system. I can answer questions about the workflow, different roles (HOD, Coordinator, Faculty, Student), how the Free Rider AI scoring works, GitHub tracking, and PDF reports!"
        
    if 'what' in msg and ('can' in msg or 'do' in msg or 'tell' in msg):
        return "I can tell you everything about this platform! Ask me about: \n- Roles (e.g. 'what does the HOD do?')\n- AI Scoring (e.g. 'how does risk calculation work?')\n- GitHub Sync (e.g. 'how is activity tracked?')\n- Project submission and management."
        
    if 'help' in msg:
        return "Sure! Try asking me about 'roles', 'AI scoring', 'GitHub tracking', or 'project proposals'."

    return "I'm sorry, I don't have information on that specific topic. Try asking about roles, AI scoring, GitHub tracking, or reports!"

from app import csrf

@chatbot.route('/api/chat', methods=['POST'])
@csrf.exempt
def chat():
    print("Chatbot endpoint hit!")
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({'response': 'Please provide a message.'}), 400
        
    user_message = data['message']
    response_text = mock_ai_response(user_message)
    
    return jsonify({'response': response_text})
