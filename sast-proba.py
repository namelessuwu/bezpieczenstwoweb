password = "maselko123"

import sqlite3
from flask import request, Flask

app = Flask(__name__)
conn = sqlite3.connect('test.db')

@app.route("/user")
def get_user():
    username = request.args.get("username")
    query = f"SELECT * FROM users WHERE name = '{username}'"
    cursor = conn.cursor()
    cursor.execute(query) # SQL Injection
    return str(cursor.fetchall())
