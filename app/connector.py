import mysql.connector
import os


def conn_to_db():
    conn = mysql.connector.connect(
        user=os.environ.get('MYSQL_USER'),
        password=os.environ.get('MYSQL_ROOT_PASSWORD'),
        host=os.environ.get('MYSQL_HOST'),
        port=3306,
        database="flaskshop"
    )
    return conn


def fetch(quantity, query, params=()):
    conn = conn_to_db()
    cur = conn.cursor()
    cur.execute(query, params)
    if quantity == "one":
        data = cur.fetchone()
    elif quantity == "all":
        data = cur.fetchall()
    else:
        data = None
    conn.close()
    return data
    
def insert(query, params=()):
    conn = conn_to_db()
    cur = conn.cursor()
    cur.execute(query, params)
    conn.commit()
    conn.close()
