import cv2
import numpy as np
import face_recognition
from firebase_admin import db

# ✅ Face se single embedding
def get_face_embedding(face_image):
    try:
        small_image = cv2.resize(face_image, (0, 0), fx=0.25, fy=0.25)
        rgb = cv2.cvtColor(small_image, cv2.COLOR_BGR2RGB)
        face_locations = face_recognition.face_locations(rgb)

        if not face_locations:
            print("[ERROR] No face found in image.")
            return None

        encodings = face_recognition.face_encodings(rgb, face_locations)
        return encodings[0] if encodings else None
    except Exception as e:
        print(f"[ERROR] Face encoding failed: {e}")
        return None

# ✅ Multiple faces crop karna
def extract_faces(image):
    try:
        rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        face_locations = face_recognition.face_locations(rgb)
        face_images = []

        for (top, right, bottom, left) in face_locations:
            face_img = rgb[top:bottom, left:right]
            if face_img.size == 0:
                continue
            try:
                face_img = cv2.resize(face_img, (160, 160))
                face_images.append(face_img)
            except Exception as e:
                print(f"[WARNING] Resize failed: {e}")
                continue
        return face_images
    except Exception as e:
        print(f"[ERROR] extract_faces failed: {e}")
        return []

# ✅ Extract encodings (used by mark_attendance_api)
def extract_face_encodings(image):
    try:
        small_image = cv2.resize(image, (0, 0), fx=0.5, fy=0.5)
        rgb = cv2.cvtColor(small_image, cv2.COLOR_BGR2RGB)
        face_locations = face_recognition.face_locations(rgb)
        print("Face location found:", face_locations)  

        if not face_locations:
            print("[ERROR] No face found for encoding")
            return []

        face_encodings = face_recognition.face_encodings(rgb, face_locations)
        return face_encodings
    except Exception as e:
        print(f"[ERROR] extract_face_encodings failed: {e}")
        return []

# ✅ Firebase se embeddings load karna
def get_registered_embeddings():
    try:
        ref = db.reference("face_metadata")
        data = ref.get()
    except Exception as e:
        print(f"[ERROR] Firebase access failed: {e}")
        return []

    known = []
    if data:
        for key, entry in data.items():
            embeddings = entry.get('embeddings', [])
            if embeddings:
                try:
                    embeddings = [np.array(embedding) for embedding in embeddings]
                    known.append({
                        'name': entry.get('name'),
                        'id_or_email': entry.get('id_or_email', entry.get('email')),
                        'embeddings': embeddings
                    })
                except Exception as e:
                    print(f"[WARNING] Embedding parse failed for {key}: {e}")
    return known

# ✅ Compare face with registered embeddings
def recognize_faces(detected_faces, known_data, threshold=0.5):
    results = []

    for face in detected_faces:
        embedding = get_face_embedding(face)
        if embedding is None:
            results.append({'name': 'Unknown', 'status': 'absent'})
            continue

        match_found = False
        for record in known_data:
            for known_emb in record['embeddings']:
                distance = np.linalg.norm(np.array(known_emb) - embedding)
                if distance < threshold:
                    results.append({
                        'name': record['name'],
                        'id_or_email': record['id_or_email'],
                        'match_score': round(1 - distance, 3),
                        'status': 'present'
                    })
                    match_found = True
                    break
            if match_found:
                break

        if not match_found:
            results.append({'name': 'Unknown', 'status': 'absent'})
    return results
