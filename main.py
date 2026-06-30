from app import create_app, db
from app.agent.background_agent import start_agent

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    
    # Start the daily background monitoring agent
    start_agent(app)
    
    # Trigger an immediate run for feedback
    with app.app_context():
        from app.agent.background_agent import collect_and_analyze
        collect_and_analyze(app)
    
    app.run(debug=True, use_reloader=False) # use_reloader=False to avoid starting agent twice
