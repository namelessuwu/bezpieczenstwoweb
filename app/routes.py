from flask import render_template, request, redirect, url_for, session, abort
from app import app
from connector import fetch, insert
from models import Product, User, Order
from forms import LoginForm, RegistrationForm, OrderForm, SubmitForm
from flask_login import current_user, login_user, logout_user, login_required
from datetime import datetime


@app.route('/')
@app.route('/index')
def index():
    product_data = fetch('all', "SELECT * FROM products")
    products = [Product(*product) for product in product_data]
    return render_template('index.html', products=products)


@app.route('/product/<int:id>')
def product(id):
    form = SubmitForm()
    product_data = fetch('one', "SELECT * FROM products WHERE product_id=%s", (id,))
    if product_data:
        product = Product(*product_data)
        return render_template('product.html', product=product, form=form)
    else:
        abort(404)


@app.route('/login', methods=['POST','GET'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    login_form = LoginForm()
    if login_form.validate_on_submit():
        user_data = fetch("one", "SELECT * FROM users WHERE username=%s", (login_form.username.data,))
        if user_data:   
            user = User(*user_data)
        else:
            user = None
        if user is None or not user.check_password(login_form.password.data):
            return redirect(url_for('index'))
        login_user(user)
        return redirect(url_for('index'))
    return render_template('login.html', login_form=login_form)


@app.route('/signin', methods=['POST', 'GET'])
def signin():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    registration_form = RegistrationForm()
    if registration_form.validate_on_submit():
        user = User(username=registration_form.username.data, email=registration_form.email.data, user_id=None, password_hash=None)
        user.set_password(registration_form.password.data)
        insert("INSERT INTO users (username,email,password) VALUES (%s, %s, %s)",
               (user.username, user.email, user.password_hash))
        return redirect(url_for('index'))
    return render_template('signin.html', registration_form=registration_form)

@app.route('/logout')
def logout():
    logout_user()
    session.clear()
    return redirect(url_for('index'))

@app.route('/orders')
@login_required
def orders():
    id = current_user.user_id
    orders = None
    order_data = fetch('all', 'SELECT * FROM orders WHERE user_id=%s', (int(id),))
    if order_data:
        orders = [Order(*order) for order in order_data]
    return render_template('orders.html', orders=orders)

@app.route('/checkout')
def checkout():
    form = OrderForm()
    return render_template('checkout.html', form=form)

@app.route('/addToCart/<int:id>', methods=['POST'])
def addToCart(id):
    product_data = fetch('one', "SELECT * FROM products WHERE product_id=%s", (id,))
    if not product_data:
        abort(404)
    product = Product(*product_data)    

    if 'cart' not in session:
        session['cart'] = {}
    cart = session['cart']

    if str(product.product_id) in cart:
        cart[str(product.product_id)]['quantity'] += 1
        cart[str(product.product_id)]['price'] = float(cart[str(product.product_id)]['price']) + float(product.price)
    else:
        cart[str(product.product_id)] = {
            'name': product.name,
            'quantity': 1,
            'price': float(product.price)
        }

    session['cart'] = cart

    return redirect(url_for('checkout'))

@app.route('/order', methods=['POST'])
def order():
    form = OrderForm()
    if form.validate_on_submit():
        user_id = current_user.user_id
        total_amount = 0
        for product in session['cart']:
            total_amount += session['cart'][product]['quantity'] * session['cart'][product]['price']
        order = Order(order_id=None, user_id=user_id, address=form.address.data, phone_number=form.phone_number.data, order_date=datetime.now(), total_amount=total_amount)
        insert("INSERT INTO orders (user_id, address, phone_number, order_date, total_amount) VALUES (%s, %s, %s, %s, %s)",
               (order.user_id, order.address, order.phone_number, order.order_date, order.total_amount))
        session['cart'] = {}
        return redirect(url_for('orders'))
    return redirect(url_for('index'))


@app.route('/admin/orders')
@login_required
def admin_orders():
    if current_user.is_authenticated:
        if current_user.username == 'admin':
            form = SubmitForm()
            orders = None
            order_data = fetch('all', 'SELECT * FROM orders')
            if order_data:
                orders = [Order(*order) for order in order_data]
            return render_template('admin_orders.html', orders=orders, form=form)
    abort(403)
    return redirect(url_for('index'))


@app.route('/admin/users')
@login_required
def admin_users():
    if current_user.is_authenticated:
        if current_user.username == 'admin':
            form = SubmitForm()
            users = None
            user_data = fetch('all', 'SELECT * FROM users')
            if user_data:
                users = [User(*user) for user in user_data]
            return render_template('admin_users.html', users=users, form=form)
    abort(403)
    return redirect(url_for('index'))


@app.route('/admin/delete_order/<int:order_id>', methods=['POST'])
@login_required
def delete_order(order_id):
    if current_user.username == 'admin':
        order_data = fetch('one', "SELECT * FROM orders WHERE order_id=%s", (order_id,))
        if order_data:
            insert("DELETE FROM orders WHERE order_id=%s", (order_id,))
            return redirect(url_for('admin_orders'))
        abort(404)
    else:
        abort(403)


@app.route('/admin/delete_user/<int:user_id>', methods=['POST'])
@login_required
def delete_user(user_id):
    if current_user.username == 'admin':
        user_data = fetch('one', "SELECT * FROM users WHERE user_id=%s", (user_id,))
        if user_data:
            insert("DELETE FROM orders WHERE user_id=%s", (user_id,))
            insert("DELETE FROM users WHERE user_id=%s", (user_id,))
            return redirect(url_for('admin_users'))
        abort(404)
    else:
        abort(403)
