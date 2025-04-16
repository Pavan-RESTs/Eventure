import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase Admin
cred = credentials.Certificate(r"C:\Users\pavan\Downloads\eventure-22uit104-firebase-adminsdk-fbsvc-532e88f334.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# List of departments extracted from the image
departments = [
    "IT - Information Technology",
    "EEE - Electrical & Electronics Engineering",
    "CSE - Computer Science Engineering",
    "ECE - Electronics & Communication Engineering",
    "ICE - Instrumentation & Control Engineering",
    "ME - Mechanical Engineering",
    "CV - Civil Engineering",
    "BME - Bio Medical Engineering",
    "MCE - Mechatronics Engineering",
    "CSBS - Computer Science & Business Systems",
    "AIDS - Artificial Intelligence & Data Science",
    "PG-ECE - Electronics & Communication Engineering",
    "PG-CSE - Computer Science Engineering",
    "PG-AIDS - Artificial Intelligence & Data Science",
    "PG-ME - Manufacturing Engineering",
    "MCA - Master of Computer Applications",
    "MBA - Master of Business Administration",
    "Ph.D - Mechanical Engineering",
    "Ph.D - Electrical & Electronics Engineering",
    "Ph.D - Electronics & Communication Engineering",
    "Ph.D - Computer Science Engineering",
    "Ph.D - Information Technology",
    "Ph.D - Business Administration",
    "Ph.D - Civil Engineering",
    "Ph.D - Physice/Chemistry/Mathematics/English",
    "B.Arch - Bachelor of Architecture",
    "M.Com - Commerce",
    "M.Sc - Computer Science",
    "M.Sc - Physics",
    "M.Sc - Chemistry",
    "M.A - English",
    "B.Com - Professional Accounting",
    "B.Com - General",
    "B.Com - Computer Applications",
    "B.Com - Corporate Secretaryship",
    "B.Com - Accounting and Finance",
    "B.Com - Cost and Management Accounting",
    "BBA - Business Administration",
    "BBA - Fintech and Digital Banking",
    "BCA - Computer Applications",
    "B.Sc - Computer Science",
    "B.Sc - Data Science and Analytics",
    "B.Sc - Physics",
    "B.Sc - Chemistry",
    "B.Sc - Microbiology",
    "B.Sc - Biotechnology",
    "B.Sc - Nutrition and Dietetics",
    "B.Sc - Visual Communication",
    "B.A - English",
    "B.A - Tamil",
    "B.A - French",
    "B.A - Journalism and Mass Communication",
    "BPT - Bachelor of Physiotherapy",
    "B.Sc - Agriculture (Hons)",
    "B.Sc - Horticulture (Hons)",
    "B.Pharm - Bachelor of Pharmacy",
    "D.Pharm - Diploma in Pharmacy",
    "LL.B - Bachelor of Law",
    "B.A.LL.B - Arts and Law",
    "B.Sc.LL.B - Science and Law",
    "BBA.LL.B - Business Administration and Law",
    "B.Sc - Critical Care Technology",
    "B.Sc - Cardiac Lab Technology",
    "B.Sc - Emergency Medicine Technology",
    "B.Sc - Medical Lab Technology",
    "B.Sc - Operation Theatre and Anesthesia Technology",
    "B.Sc - Renal Dialysis Technology",
    "B.Sc - Radiology and Imaging Technology",
    "B.Sc - Cardiac Perfusion Technology",
    "B.Sc - Neuro Care Technology",
    "B.Sc - Respiratory Care Technology",
    "B.Sc - Reproductive Medicine and Clinical Embryology",
    "B.Sc - Urocare Technology",
    "B.Sc - Hematology and Blood Banking Technology",
    "B.Sc - Optometry",
    "DMLT - Medical Lab Technology",
    "DOTAT - Operation Theatre and Anesthesia Technology",
    "DRGIT - Radiography and Imaging Technology"
]

# Define the fixed timestamp
created_at = datetime(2025, 4, 10, 20, 15, 41)

# Upload to Firestore
for i, dept in enumerate(departments, start=1):
    doc_ref = db.collection("Department Table").document(str(i))
    doc_ref.set({
        "name": dept,
        "created_at": created_at
    })

print("Departments uploaded successfully.")
