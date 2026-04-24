from flask import Blueprint, request, jsonify
from models.database import db
from models.dress_post import DressPost
from models.favorite import Favorite, TailorDressLink
from models.user import User

posts_bp = Blueprint("posts", __name__)

@posts_bp.route("/", methods=["GET"])
def get_posts():
    category = request.args.get("category", "")
    if category:
        posts = DressPost.query.filter_by(is_public=True, category=category).order_by(DressPost.created_at.desc()).all()
    else:
        posts = DressPost.query.filter_by(is_public=True).order_by(DressPost.created_at.desc()).all()
    result = []
    for p in posts:
        d = p.to_dict()
        tailors = []
        for link in p.tailor_links:
            t = User.query.get(link.tailor_id)
            if t and t.is_public:
                tailors.append({
                    'id': t.id,
                    'name': t.name,
                    'contact_info': t.contact_info,
                    'location': t.location,
                    'years_experience': t.years_experience,
                    'phone': t.phone,
                })
        d['tailors'] = tailors
        result.append(d)
    return jsonify(result)

@posts_bp.route("/", methods=["POST"])
def create_post():
    data = request.get_json()
    post = DressPost(
        uploader_id=data["uploader_id"],
        title=data["title"],
        description=data.get("description", ""),
        category=data["category"],
        image_url=data.get("image_url", ""),
        price=data.get("price", 0),
        estimated_days=data.get("estimated_days", 7),
        is_public=data.get("is_public", True),
    )
    db.session.add(post)
    db.session.commit()
    if data.get("link_tailor") and data.get("tailor_id"):
        link = TailorDressLink(tailor_id=data["tailor_id"], post_id=post.id)
        db.session.add(link)
        db.session.commit()
    return jsonify(post.to_dict()), 201

@posts_bp.route("/<int:id>", methods=["DELETE"])
def delete_post(id):
    post = DressPost.query.get_or_404(id)
    db.session.delete(post)
    db.session.commit()
    return jsonify({"message": "Deleted"})

@posts_bp.route("/<int:id>/favorite", methods=["POST"])
def toggle_favorite(id):
    data = request.get_json()
    user_id = data["user_id"]
    existing = Favorite.query.filter_by(user_id=user_id, post_id=id).first()
    if existing:
        db.session.delete(existing)
        db.session.commit()
        return jsonify({"favorited": False})
    fav = Favorite(user_id=user_id, post_id=id)
    db.session.add(fav)
    db.session.commit()
    return jsonify({"favorited": True})

@posts_bp.route("/favorites/<int:user_id>", methods=["GET"])
def get_favorites(user_id):
    favs = Favorite.query.filter_by(user_id=user_id).all()
    result = []
    for f in favs:
        post = DressPost.query.get(f.post_id)
        if post:
            result.append(post.to_dict())
    return jsonify(result)
