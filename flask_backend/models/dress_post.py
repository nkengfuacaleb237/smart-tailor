from models.database import db
from datetime import datetime

class DressPost(db.Model):
    __tablename__ = 'dress_posts'
    id = db.Column(db.Integer, primary_key=True)
    uploader_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.String(500), default='')
    category = db.Column(db.String(100), nullable=False)
    image_url = db.Column(db.String(500), default='')
    price = db.Column(db.Float, default=0)
    estimated_days = db.Column(db.Integer, default=7)
    likes = db.Column(db.Integer, default=0)
    is_public = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    tailor_links = db.relationship('TailorDressLink', backref='post', lazy=True)
    favorites = db.relationship('Favorite', backref='post', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'uploader_id': self.uploader_id,
            'title': self.title,
            'description': self.description,
            'category': self.category,
            'image_url': self.image_url,
            'price': self.price,
            'estimated_days': self.estimated_days,
            'likes': self.likes,
            'is_public': self.is_public,
            'created_at': str(self.created_at),
        }
