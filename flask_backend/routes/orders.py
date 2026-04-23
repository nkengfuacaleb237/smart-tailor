from flask import Blueprint, request, jsonify
from models.database import db
from models.order import Order

orders_bp = Blueprint("orders", __name__)

@orders_bp.route("/", methods=["POST"])
def create_order():
    data = request.get_json()
    order = Order(
        customer_id=data["customer_id"],
        tailor_id=data["tailor_id"],
        post_id=data["post_id"],
        note=data.get("note", ""),
    )
    db.session.add(order)
    db.session.commit()
    return jsonify(order.to_dict()), 201

@orders_bp.route("/tailor/<int:tailor_id>", methods=["GET"])
def get_tailor_orders(tailor_id):
    status = request.args.get("status", "")
    if status:
        orders = Order.query.filter_by(tailor_id=tailor_id, status=status).order_by(Order.created_at.desc()).all()
    else:
        orders = Order.query.filter_by(tailor_id=tailor_id).order_by(Order.created_at.desc()).all()
    return jsonify([o.to_dict() for o in orders])

@orders_bp.route("/<int:id>/status", methods=["PATCH"])
def update_order_status(id):
    data = request.get_json()
    order = Order.query.get_or_404(id)
    order.status = data["status"]
    db.session.commit()
    return jsonify(order.to_dict())
