
import sqlite3
import os

db_path = os.path.join('instance', 'project.db')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Update Chetan's GitHub username
cursor.execute("UPDATE user SET github_username='Chetan-garoor' WHERE username='Chetan'")
print(f"Updated {cursor.rowcount} rows for 'Chetan'.")

# Also update Vishwa if needed (Revanasiddappaa0607 seems to be a real user, maybe it belongs to Vishwa?)
cursor.execute("UPDATE user SET github_username='Revanasiddappaa0607' WHERE username='Vishwa_jawalagi'")
print(f"Updated {cursor.rowcount} rows for 'Vishwa_jawalagi'.")

conn.commit()
conn.close()
