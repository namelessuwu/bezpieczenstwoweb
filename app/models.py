from time import time
import jwt
from connector import fetch
import os
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash


class User(UserMixin):
    def __init__(self, user_id, username, email, password_hash):
        self.user_id = user_id
        self.username = username
        self.email = email
        self.password_hash = password_hash
    
    def get_id(self):
        return (self.user_id)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def get_reset_password_token(self, expires_in=600):
        return jwt.encode(
            {'reset_password': self.user_id, 'exp': time() + expires_in},
            os.environ.get('SECRET_KEY'), algorithm='HS256')
    
    @staticmethod
    def verify_reset_password_token(token):
        try:
            id = jwt.decode(token, os.environ.get('SECRET_KEY'),
                            algorithms=['HS256'])['reset_password']
        except:
            return
        return fetch('one', 'SELECT * FROM users WHERE user_id=%s', (id,))
    
class Product():
    def __init__(self, product_id, name, description, price):
        self.product_id = product_id
        self.name = name
        self.description = description
        self.price = price        

class Order():
    def __init__(self, order_id, user_id, address, phone_number, order_date, total_amount):
        self.order_id = order_id
        self.user_id = user_id
        self.address = address
        self.phone_number = phone_number
        self.order_date = order_date
        self.total_amount = total_amount