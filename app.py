from flask import Flask
import firebase_admin
from firebase_admin import credentials, db
from register_api import register_api  
from login_api import login_api
from mark_attendance_api import mark_attendance_api

app = Flask(__name__)


if not firebase_admin._apps:
    cred = credentials.Certificate("faceapp-8c4ab-firebase-adminsdk-fbsvc-d3682fdbe3.json")
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://faceapp.firebaseio.com/'
    })


app.register_blueprint(register_api,url_prefix='/api')
app.register_blueprint(login_api, url_prefix='/api')
app.register_blueprint(mark_attendance_api, url_prefix='/api')

if __name__ == "__main__":
    app.run(debug=True, host='192.168.100.15', port=5000)
