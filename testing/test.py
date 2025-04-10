import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

# Path to your Firebase service account key JSON file
cred = credentials.Certificate(r"C:\Users\pavan\Downloads\eventure-22uit104-firebase-adminsdk-fbsvc-5a072e942b.json")
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

# Create sample event data
event_id = "test_event_0011"
event_data = {
    "created_at": firestore.SERVER_TIMESTAMP,
    "name": "Test Event11",
    "description": "This is a test event added from Python.",
    "user_id": "user123",
    "department_id": "dept001",
    "venue_id": "venue001",
    "likes": 5,
    "start_timestamp": datetime.now() + timedelta(days=1),
    "end_timestamp": datetime.now() + timedelta(days=2),
}

# Insert the document with a specific ID (so doc.id == event_id)
db.collection("Event Table").document(event_id).set(event_data)

print(f"✅ Test event '{event_id}' inserted successfully.")
