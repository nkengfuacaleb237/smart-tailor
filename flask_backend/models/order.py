from models.database import db
from datetime import datetime

class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    tailor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    post_id = db.Column(db.Integer, db.ForeignKey('dress_posts.id'), nullable=False)
    status = db.Column(db.String(20), default='pending')
    note = db.Column(db.String(500), default='')
    budget = db.Column(db.Float, default=0)
    location = db.Column(db.String(200), default='')
    color_preference = db.Column(db.String(200), default='')
    style_preference = db.Column(db.String(300), default='')
    chest = db.Column(db.Float, default=0)
    waist = db.Column(db.Float, default=0)
    hips = db.Column(db.Float, default=0)
    shoulder = db.Column(db.Float, default=0)
    sleeve = db.Column(db.Float, default=0)
    inseam = db.Column(db.Float, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship('User', foreign_keys=[customer_id])
    tailor = db.relationship('User', foreign_keys=[tailor_id])
    post = db.relationship('DressPost', foreign_keys=[post_id])

    def to_dict(self):
        return {
            'id': self.id,
            'customer_id': self.customer_id,
            'tailor_id': self.tailor_id,
            'post_id': self.post_id,
            'status': self.status,
            'note': self.note,
            'budget': self.budget,
            'location': self.location,
            'color_preference': self.color_preference,
            'style_preference': self.style_preference,
            'chest': self.chest,
            'waist': self.waist,
            'hips': self.hips,
            'shoulder': self.shoulder,
            'sleeve': self.sleeve,
            'inseam': self.inseam,
            'created_at': str(self.created_at),
            'customer_name': self.customer.name if self.customer else '',
            'tailor_name': self.tailor.name if self.tailor else '',
            'post_title': self.post.title if self.post else '',
            'post_category': self.post.category if self.post else '',
            'post_price': self.post.price if self.post else 0,
            'post_image': self.post.image_url if self.post else '',
        }
