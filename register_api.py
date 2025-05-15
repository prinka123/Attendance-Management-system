from flask import Blueprint, request, jsonify
import os
import cv2
import numpy as np
from firebase_admin import db
from face_utils import get_face_embedding
import datetime
import hashlib

register_api = Blueprint('register_api', __name__)

@register_api.route('/register_user', methods=['POST'])
def register_user():
    try:
        name = request.form.get('name')
        email = request.form.get('email')
        password = request.form.get('password')
        role = request.form.get('role', '').strip().lower()

        if not all([name, email, password, role]):
            return jsonify({"status": "fail", "message": "Missing fields"}), 400

        if role not in ['student', 'teacher']:
            return jsonify({"status": "fail", "message": "Invalid role"}), 400

        sanitized_email = email.replace('.', '_')
        hashed_password = hashlib.sha256(password.encode('utf-8')).hexdigest()

        embeddings = []
        for key in request.files:
            file = request.files[key]
            img_array = np.frombuffer(file.read(), np.uint8)
            img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

            if img is None:
                print("[ERROR] Image decode failed")
                continue

            embedding = get_face_embedding(img)
            if embedding is not None:
                embeddings.append(embedding)
            else:
                print(f"[WARNING] Face not found or encoding failed for: {key}")

        if len(embeddings) == 0:
            return jsonify({"status": "fail", "message": "No valid face found in uploaded images."}), 400

        now = datetime.datetime.now().isoformat()
        metadata = {
            'name': name,
            'email': email,
            'password': hashed_password,
            'role': role,
            'date_registered': now,
            'embeddings': [e.tolist() for e in embeddings]
        }

        db.reference(f'face_metadata/{role}_{sanitized_email}').set(metadata)
        print(f"[SUCCESS] {role.capitalize()} {email} registered.")
        return jsonify({"status": "success", "message": f"{role.capitalize()} registered successfully."}), 200

    except Exception as e:
        print(f"[ERROR] Exception in /register_user: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
@register_api.route('/ping', methods=['GET'])
def ping():
    return jsonify({"message": "Flask is working ✅"})
