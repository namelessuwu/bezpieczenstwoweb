from flask import Flask
from config import Config
from connector import fetch
from models import User
from flask_login import LoginManager
from flask_mail import Mail
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
app.config.from_object(Config)
login = LoginManager(app)
login.login_view = 'login'


@login.user_loader
def load_user(user_id):
    user_data = fetch("one", "SELECT * FROM users WHERE user_id=%s", (int(user_id),))
    if user_data:
        return User(*user_data)
    return None

import routes, errors