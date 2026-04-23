from flask import Blueprint, request, jsonify
from models.database import db
from models.user import User

users_bp = Blueprint("users", __name__)

@users_bp.route("/", methods=["POST"])
def create_or_login():
    data = request.get_json()
    email = data.get("email", "").lower().strip()
    existing = User.query.filter_by(email=email).first()
    if existing:
        return jsonify(existing.to_dict()), 200
    user = User(
        name=data.get("name", ""),
        email=email,
        phone=data.get("phone", ""),
        role=data.get("role", "customer"),
        google_id=data.get("google_id", None),
        avatar_url=data.get("avatar_url", ""),
        dress_preferences=data.get("dress_preferences", ""),
        skills=data.get("skills", ""),
        years_experience=data.get("years_experience", 0),
        location=data.get("location", ""),
        contact_info=data.get("contact_info", ""),
        is_public=data.get("is_public", True),
    )
    db.session.add(user)
    db.session.commit()
    return jsonify(user.to_dict()), 201

@users_bp.route("/<int:id>", methods=["GET"])
def get_user(id):
    user = User.query.get_or_404(id)
    return jsonify(user.to_dict())

@users_bp.route("/<int:id>", methods=["PUT"])
def update_user(id):
    user = User.query.get_or_404(id)
    data = request.get_json()
    for field in ["name","phone","dress_preferences","skills","years_experience","location","contact_info","is_public","avatar_url"]:
        if field in data:
            setattr(user, field, data[field])
    db.session.commit()
    return jsonify(user.to_dict())

@users_bp.route("/tailors", methods=["GET"])
def get_public_tailors():
    tailors = User.query.filter_by(role='tailor', is_public=True).all()
    return jsonify([t.to_dict() for t in tailors])
@users_bp.route("/by-email", methods=["GET"])
def get_by_email():
    email = request.args.get("email", "").lower().strip()
    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({"error": "Not found"}), 404
    return jsonify(user.to_dict()), 200
