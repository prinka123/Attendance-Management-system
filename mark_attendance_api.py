from flask import Blueprint, request, jsonify
import numpy as np
import cv2
from firebase_admin import db
from face_utils import extract_face_encodings

mark_attendance_api = Blueprint('mark_attendance_api', __name__)

@mark_attendance_api.route('/mark_attendance', methods=['POST'])
def mark_attendance():
    try:
        if 'image' not in request.files:
            return jsonify({'status': 'fail', 'message': 'Image not provided'}), 400

        file = request.files['image']
        img_array = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        face_encodings = extract_face_encodings(img)

        if not face_encodings:
            return jsonify({'status': 'fail', 'message': 'No faces detected'}), 400

        ref = db.reference("/face_metadata")
        all_data = ref.get()

        present_students = []

        for face_encoding in face_encodings:
            for key, user in all_data.items():
                if user.get('role') != 'student':
                    continue
                stored_embeddings = [np.array(e) for e in user['embeddings']]
                for stored in stored_embeddings:
                    distance = np.linalg.norm(stored - face_encoding)
                    if distance < 0.5:
                        present_students.append(user['name'])
                        break

        return jsonify({'status': 'success', 'present': present_students}), 200

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
