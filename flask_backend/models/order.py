from models.database import db
from datetime import datetime

class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    tailor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    post_id = db.Column(db.Integer, db.ForeignKey('dress_posts.id'), nullable=False)
    status = db.Column(db.String(20), default='pending')  # pending, completed, cancelled
    note = db.Column(db.String(500), default='')
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
            'created_at': str(self.created_at),
            'customer_name': self.customer.name if self.customer else '',
            'tailor_name': self.tailor.name if self.tailor else '',
            'post_title': self.post.title if self.post else '',
            'post_category': self.post.category if self.post else '',
        }
