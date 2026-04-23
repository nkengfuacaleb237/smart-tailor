from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def init_db():
    from models.user import User
    from models.measurement import Measurement
    from models.dress_post import DressPost
    from models.tailor_customer import TailorCustomer, TailorMeasurement
    from models.favorite import Favorite, TailorDressLink
    from models.customer import Customer
    from models.order import Order
    db.create_all()
    print("Database initialized!")