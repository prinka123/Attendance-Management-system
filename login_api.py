from flask import Blueprint, request, jsonify
import numpy as np
import cv2
import face_recognition
from firebase_admin import db
import hashlib

login_api = Blueprint('login_api', __name__)
FACE_MATCH_THRESHOLD = 0.5  

@login_api.route('/login_user', methods=['POST'])
def login_user():
    try:
        email = request.form['email']
        password = request.form['password']
        role = request.form['role'].strip().lower()

        if role not in ['student', 'teacher']:
            return jsonify({'status': 'fail', 'message': 'Invalid role'}), 400

        sanitized_email = email.replace('.', '_')
        ref = db.reference(f"/face_metadata/{role}_{sanitized_email}")
        user_data = ref.get()

        if not user_data:
            return jsonify({'status': 'fail', 'message': 'User not found'}), 404

        hashed_input_password = hashlib.sha256(password.encode()).hexdigest()
        if user_data['password'] != hashed_input_password:
            return jsonify({'status': 'fail', 'message': 'Invalid password'}), 401

        if 'image' not in request.files:
            return jsonify({'status': 'fail', 'message': 'Image required'}), 400

        file = request.files['image']
        img_array = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        face_locations = face_recognition.face_locations(rgb_img)
        face_encodings = face_recognition.face_encodings(rgb_img, face_locations)

        if not face_encodings:
            return jsonify({'status': 'fail', 'message': 'No face detected'}), 400

        live_embedding = face_encodings[0]
        stored_embeddings = [np.array(e) for e in user_data['embeddings']]

        for stored in stored_embeddings:
            distance = np.linalg.norm(stored - live_embedding)
            if distance < FACE_MATCH_THRESHOLD:
                return jsonify({'status': 'success', 'message': 'Login successful', 'name': user_data['name']}), 200

        return jsonify({'status': 'fail', 'message': 'Face not matched'}), 403

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
