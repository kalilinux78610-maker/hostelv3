import os
import firebase_admin
from firebase_admin import credentials, firestore

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

doc_ids = ["6ShCN8lvwFKucbyzuvl3", "887DAlTXon62uNVx51qx"]

print("PROVING PENDING STATUS FOR THE TWO LEAVE REQUESTS:")
print("=" * 60)

for doc_id in doc_ids:
    doc_ref = db.collection("leave_requests").document(doc_id)
    doc = doc_ref.get()
    if doc.exists:
        d = doc.to_dict()
        print(f"Doc ID: {doc.id}")
        print(f"  Student Name: {d.get('name')}")
        print(f"  Branch: {d.get('branch')}")
        print(f"  Category: {d.get('category')}")
        print(f"  Hostel ID: {d.get('hostelId')}")
        print(f"  Leave Type: {d.get('leaveType')}")
        print(f"  Reason: {d.get('reason')}")
        print(f"  Start Date: {d.get('startDate')}")
        print(f"  End Date: {d.get('endDate')}")
        print(f"  Created At: {d.get('createdAt')}")
        print(f"  -------------------------------------")
        print(f"  STATUSES:")
        print(f"    Overall Status: {d.get('status')}")
        print(f"    HOD Status:     {d.get('hodStatus')}")
        print(f"    Warden Status:  {d.get('wardenStatus')}")
        print(f"    Rector Status:  {d.get('rectorStatus')}")
        print("-" * 60)
    else:
        print(f"Document {doc_id} not found!")
