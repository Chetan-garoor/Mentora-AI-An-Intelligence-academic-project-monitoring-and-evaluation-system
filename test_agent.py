from app import create_app
from app.agent.background_agent import collect_and_analyze

app = create_app()
print("Running Agent...")
collect_and_analyze(app)
print("Agent test complete.")
