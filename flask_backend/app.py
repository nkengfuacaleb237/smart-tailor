from flask import Flask
from flask_cors import CORS
from models.database import db, init_db

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://postgres:LandRegistry2024!@db.jgulojsoofrqqrsmbtvq.supabase.co:5432/postgres"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
CORS(app)
db.init_app(app)

from routes.customers import customers_bp
from routes.measurements import measurements_bp
from routes.styles import styles_bp
from routes.users import users_bp
from routes.posts import posts_bp
from routes.tailor_customers import tailor_customers_bp
from routes.orders import orders_bp

app.register_blueprint(customers_bp, url_prefix="/api/customers")
app.register_blueprint(measurements_bp, url_prefix="/api/measurements")
app.register_blueprint(styles_bp, url_prefix="/api/styles")
app.register_blueprint(users_bp, url_prefix="/api/users")
app.register_blueprint(posts_bp, url_prefix="/api/posts")
app.register_blueprint(tailor_customers_bp, url_prefix="/api/tailor-customers")
app.register_blueprint(orders_bp, url_prefix="/api/orders")

with app.app_context():
    init_db()

@app.route("/")
def home():
    return {"message": "Smart Tailor API v2"}

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
