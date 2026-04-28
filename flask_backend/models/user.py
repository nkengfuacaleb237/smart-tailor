from models.database import db
from datetime import datetime

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(200), unique=True, nullable=False)
    phone = db.Column(db.String(30), default='')
    role = db.Column(db.String(20), nullable=False)  # 'customer' or 'tailor'
    google_id = db.Column(db.String(200), unique=True, nullable=True)
    avatar_url = db.Column(db.String(500), default='')
    # Customer preferences (comma-separated categories e.g. "Ankara,Formal,Kaftan")
    dress_preferences = db.Column(db.String(500), default='')
    # Tailor-specific
    skills = db.Column(db.String(500), default='')
    years_experience = db.Column(db.Integer, default=0)
    location = db.Column(db.String(200), default='')
    contact_info = db.Column(db.String(300), default='')
    is_public = db.Column(db.Boolean, default=True)
    password_hash = db.Column(db.String(200), default='')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    measurements = db.relationship('Measurement', backref='user', lazy=True, foreign_keys='Measurement.user_id')
    posts = db.relationship('DressPost', backref='uploader', lazy=True)
    tailor_customers = db.relationship('TailorCustomer', backref='tailor', lazy=True, foreign_keys='TailorCustomer.tailor_id')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'role': self.role,
            'avatar_url': self.avatar_url,
            'dress_preferences': self.dress_preferences,
            'skills': self.skills,
            'years_experience': self.years_experience,
            'location': self.location,
            'contact_info': self.contact_info,
            'is_public': self.is_public,
            'created_at': str(self.created_at),
        }