import urllib.request
import json

url = "https://firestore.googleapis.com/v1/projects/hostel-v3/databases/(default)/documents/leave_requests"

try:
    print("Fetching from:", url)
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        res_data = response.read()
        data = json.loads(res_data.decode("utf-8"))
        
        documents = data.get("documents", [])
        print(f"Total documents returned: {len(documents)}")
        for doc in documents:
            fields = doc.get("fields", {})
            name = fields.get("name", {}).get("stringValue", "Unknown")
            branch = fields.get("branch", {}).get("stringValue", "Unknown")
            category = fields.get("category", {}).get("stringValue", "Unknown")
            status = fields.get("status", {}).get("stringValue", "Unknown")
            hod_status = fields.get("hodStatus", {}).get("stringValue", "Unknown")
            warden_status = fields.get("wardenStatus", {}).get("stringValue", "Unknown")
            hostel_id = fields.get("hostelId", {}).get("stringValue", "Unknown")
            
            print(f"Name: {name}")
            print(f"  Category: {category}")
            print(f"  Branch: {branch}")
            print(f"  Hostel ID: {hostel_id}")
            print(f"  Status: {status}")
            print(f"  HOD Status: {hod_status}")
            print(f"  Warden Status: {warden_status}")
            print("-" * 40)
except Exception as e:
    print("Error:", e)
