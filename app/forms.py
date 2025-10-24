from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField
from wtforms.validators import ValidationError, DataRequired, Email, EqualTo, Length
from connector import fetch


class LoginForm(FlaskForm):
    username = StringField("Username", validators=[DataRequired()])
    password = PasswordField("Password", validators=[DataRequired()])
    submit = SubmitField("Log in")


class RegistrationForm(FlaskForm):
    username = StringField("Username", validators=[DataRequired()])
    email = StringField("Email address", validators=[DataRequired(), Email()])
    password = PasswordField("Password", validators=[DataRequired(), Length(min=8, message="Your password must be at least 8 characters long.")])
    password2 = PasswordField("Repeat your password", validators=[DataRequired(), EqualTo("password")])
    submit = SubmitField("Sign in")

    def validate_username(self, username):
        user_data = fetch("one", "SELECT username FROM users WHERE username=%s", (username.data,))
        if user_data is not None:  
            raise ValidationError("This username is unavailable.")
    
    def validate_email(self, email):
        user_data = fetch("one", "SELECT email FROM users WHERE email=%s", (email.data,))
        if user_data is not None:
            raise ValidationError("This email address in unavailable.")


class OrderForm(FlaskForm):
    address = StringField("Address", validators=[DataRequired()])
    zip_code = StringField("Zip-code", validators=[DataRequired()])
    phone_number = StringField("Phone number", validators=[DataRequired()])
    submit = SubmitField("Order")


class ResetPasswordRequestForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    submit = SubmitField('Request Password Reset')


class ResetPasswordForm(FlaskForm):
    password = PasswordField('Password', validators=[DataRequired(), Length(min=8, message="Your password must be at least 8 characters long.")])
    password2 = PasswordField(
        'Repeat Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Reset Password')
