import os
import firebase_admin
from firebase_admin import credentials, firestore

# Parse .env file manually
env = {}
env_path = os.path.join(os.path.dirname(__file__), ".env")
with open(env_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("=", 1)
        if len(parts) == 2:
            key = parts[0].strip()
            val = parts[1].strip()
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            env[key] = val

private_key = env["FCM_PRIVATE_KEY"].replace("\\n", "\n")

cred_dict = {
    "type": "service_account",
    "project_id": env["FCM_PROJECT_ID"],
    "private_key_id": env["FCM_PRIVATE_KEY_ID"],
    "private_key": private_key,
    "client_email": env["FCM_CLIENT_EMAIL"],
    "client_id": env["FCM_CLIENT_ID"],
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": f"https://www.googleapis.com/robot/v1/metadata/x509/{env['FCM_CLIENT_EMAIL'].replace('@', '%40')}"
}

cred = credentials.Certificate(cred_dict)
firebase_admin.initialize_app(cred)

db = firestore.client()

# Fetch wardens
docs = db.collection("users").where("role", "==", "warden").stream()
print("WARDENS IN DATABASE:")
print("=" * 60)
for doc in docs:
    d = doc.to_dict()
    print(f"Email: {d.get('email')}")
    print(f"  Name: {d.get('name')}")
    print(f"  Role: {d.get('role')}")
    print(f"  Assigned Hostels: {d.get('assignedHostels')}")
    print(f"  Assigned Categories: {d.get('assignedCategories')}")
    print("-" * 60)
