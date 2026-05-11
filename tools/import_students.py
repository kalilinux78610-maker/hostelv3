"""
╔══════════════════════════════════════════════════════════════════════════╗
║  HOSTEL STUDENT BULK IMPORTER                                           ║
║  Reads: "Hostel Student List - Form Responses 1 (1).csv"                ║
║  Writes: Firestore → student_imports/{email}                            ║
║                                                                          ║
║  HOW TO RUN:                                                             ║
║    1. pip install firebase-admin                                          ║
║    2. Download serviceAccountKey.json from Firebase Console              ║
║       (Project Settings → Service Accounts → Generate New Private Key)   ║
║    3. Place serviceAccountKey.json in this folder (tools/)               ║
║    4. python import_students.py                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
"""

import csv
import re
import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore

# ─────────────────────────────────────────────────────────────
#  CONFIG — adjust paths as needed
# ─────────────────────────────────────────────────────────────
CSV_PATH = r"S:\hostelv3\Book2.csv"
SERVICE_ACCOUNT_KEY = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")

# ─────────────────────────────────────────────────────────────
#  HOSTEL → canonical name mapping (matches AppConfig.hostels)
# ─────────────────────────────────────────────────────────────
HOSTEL_MAP = {
    "ngp boy":               "NGP Boy's Hostel",
    "ngpp boy":              "NGPP Boy's Hostel",
    "nilanbhai":             "Nilanbhai Vyas Boys' Hostel",
    "workshop boy":          "Workshop Boy's Hostel",
    "workshop girl":         "Workshop Girl's Hostel",
    "sardar":                "Sardar Hostel (Piplawali)",
    "pjmf":                  "PJMF Girl's Hostel",
}

HOSTEL_CODES = {
    "NGP Boy's Hostel":           "NGP",
    "NGPP Boy's Hostel":          "NGPP",
    "Nilanbhai Vyas Boys' Hostel": "NVBH",
    "Workshop Boy's Hostel":      "WBH",
    "Workshop Girl's Hostel":     "WGH",
    "Sardar Hostel (Piplawali)":  "SH",
    "PJMF Girl's Hostel":         "PJMF",
}

# ─────────────────────────────────────────────────────────────
#  BRANCH → canonical name (mirrors canonical_names.dart)
# ─────────────────────────────────────────────────────────────
def canonicalize_branch(branch_raw: str, category: str) -> str:
    b = branch_raw.strip().lower().replace(".", "").strip()
    # Both categories — catch I.M.B.A / IMBA regardless of category
    if b in ("imba", "i mba", "integrated mba", "intmba",
             "integrated mba 5 years", "integrated mba (5 years)"):
        return "Integrated MBA (5 Years)"
    if category == "Degree":
        if b in ("cse", "computer science", "computer engineering",
                 "computer science engineering", "cs",
                 "computer science and engineering",
                 "be computer science and engineering",
                 "computer"):
            return "Computer Science & Engineering"
        if b in ("it", "information technology"):
            return "Information Technology"
        if b in ("mech", "mechanical", "mechanical engineering"):
            return "Mechanical Engineering"
        if b in ("civil", "civil engineering", "ce"):
            return "Civil Engineering"
        if b in ("ele", "elec", "electrical", "electrical engineering", "ee"):
            return "Electrical Engineering"
        if b in ("chem", "chemical", "chemical engineering", "ch",
                 "chemical department", "cemical department"):
            return "Chemical Engineering"
        if b in ("msc it", "msc-it", "m sc it", "mscit",
                 "int mscit", "integrated mscit", "i msc it",
                 "integrated msc it", "int msc it", "i msc(it)",
                 "int msc(it)", "int msc(it)", "int msc(it)"):
            return "M.Sc. IT"
        if "msc" in b and "it" in b:
            return "M.Sc. IT"
        if b in ("bba", "mba", "integrated mba", "imba", "i mba",
                 "integrated mba 5 years", "mba department",
                 "integrated mba (5 years)"):
            return "Integrated MBA (5 Years)"
        if b in ("sd", "software development") or "software dev" in b:
            return "B.Voc - Software Development"
        if "industrial chemistry" in b or b == "ic":
            return "B.Voc - Industrial Chemistry"
        if "production technology" in b or b == "pt":
            return "B.Voc - Production Technology"
        if "animation" in b or "vfx" in b or b == "avfx":
            return "B.Voc - Animation & VFX"
        if "building" in b or "construction" in b or b == "bc":
            return "B.Voc - Building and Construction"
        if "solar" in b or "renewable" in b or "sre" in b:
            return "B.Voc - Solar & Renewable Energy"
        if "wealth" in b or b == "wm":
            return "B.Voc - Wealth Management"
        if b in ("bvoc", "b voc", "b-voc"):
            return "B.Voc - Software Development"
        # Pharmacy — keep as-is
        if "pharmacy" in b or "pharm" in b:
            return "Pharmacy"
    elif category == "Diploma":
        if b in ("cse", "cs", "computer engineering", "computer science",
                 "com.science", "computer"):
            return "Computer Engineering"
        if b in ("it", "information technology"):
            return "Information Technology"
        if b in ("mech", "mechanical", "mechanical engineering"):
            return "Mechanical Engineering"
        if b in ("civil", "civil engineering", "ce"):
            return "Civil Engineering"
        if b in ("ele", "elec", "electrical", "electrical engineering", "electrical engineer department"):
            return "Electrical Engineering"
        if b in ("chem", "chemical", "chemical engineering", "chemical department"):
            return "Chemical Engineering"
    return branch_raw.strip()


# ─────────────────────────────────────────────────────────────
#  CATEGORY
# ─────────────────────────────────────────────────────────────
def canonicalize_category(institute: str, program: str) -> str:
    inst = institute.strip().lower()
    prog = program.strip().lower()
    if "ngpp" in inst or "diploma" in prog or inst == "ngpp":
        return "Diploma"
    return "Degree"


# ─────────────────────────────────────────────────────────────
#  HOSTEL
# ─────────────────────────────────────────────────────────────
def canonicalize_hostel(raw: str) -> str:
    lower = raw.strip().lower()
    for key, canonical in HOSTEL_MAP.items():
        if key in lower:
            return canonical
    return raw.strip()  # fallback — keep original


# ─────────────────────────────────────────────────────────────
#  PHONE NUMBER — strip spaces, +91, and .00 suffix
# ─────────────────────────────────────────────────────────────
def clean_phone(raw: str) -> str:
    val = raw.strip()
    # Remove .00 suffix from numbers stored as float
    val = re.sub(r'\.0+$', '', val)
    # Remove +91 prefix
    val = re.sub(r'^\+91\s*', '', val)
    val = re.sub(r'^91\s*', '', val) if len(val.replace(" ", "")) > 10 else val
    # Remove all spaces
    val = val.replace(" ", "")
    # Remove any non-digit characters EXCEPT leading +
    val = re.sub(r'[^\d]', '', val)
    return val[-10:] if len(val) > 10 else val  # keep last 10 digits


# ─────────────────────────────────────────────────────────────
#  ENROLLMENT NUMBER — strip .00
# ─────────────────────────────────────────────────────────────
def clean_enrollment(raw: str) -> str:
    val = raw.strip()
    val = re.sub(r'\.0+$', '', val)
    return val


# ─────────────────────────────────────────────────────────────
#  BLOOD GROUP — normalise
# ─────────────────────────────────────────────────────────────
def clean_blood_group(raw: str) -> str:
    val = raw.strip().upper()
    val = val.replace("POSITIVE", "+").replace("NEGATIVE", "-")
    val = val.replace("+VE", "+").replace("-VE", "-")
    val = val.replace(" ", "").replace("(", "").replace(")", "")
    return val if val not in ("", "0", "-", "NIL", "NO") else ""


# ─────────────────────────────────────────────────────────────
#  VALIDATE ROW — skip clearly invalid rows
# ─────────────────────────────────────────────────────────────
def is_valid_row(row: dict) -> bool:
    email = row.get("Student's Email", "").strip().lower()
    name  = row.get("Your Full Name (Lastname Firstname Secondname)", "").strip()
    enrol = row.get("Enrollment No.", "").strip()
    # Skip empty / header-like / test rows
    if not email or "@" not in email:
        return False
    if not name or len(name) < 3:
        return False
    if not enrol:
        return False
    # Skip clearly junk row (line 225 in CSV had date in name field)
    try:
        float(enrol)  # must be a numeric enrollment
    except ValueError:
        return False
    return True


# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────
def main():
    # ── 1. Init Firebase ─────────────────────────────────────
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌  serviceAccountKey.json not found at:\n    {SERVICE_ACCOUNT_KEY}")
        print("\n👉  Download it from Firebase Console → Project Settings → Service Accounts")
        sys.exit(1)

    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅  Firebase connected\n")

    # ── 2. Read CSV ──────────────────────────────────────────
    if not os.path.exists(CSV_PATH):
        print(f"❌  CSV not found:\n    {CSV_PATH}")
        sys.exit(1)

    with open(CSV_PATH, newline='', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"📄  Total CSV rows (incl. invalid): {len(rows)}")

    # ── 3. Process & upload ──────────────────────────────────
    batch       = db.batch()
    batch_count = 0
    BATCH_SIZE  = 400  # Firestore max is 500 ops per batch

    uploaded   = 0
    skipped    = 0
    duplicates = {}  # track duplicate emails

    for i, row in enumerate(rows, start=2):  # start=2 because row 1 is header
        if not is_valid_row(row):
            print(f"  ⚠️   Row {i:3d} SKIPPED (invalid) — name='{row.get('Your Full Name (Lastname Firstname Secondname)', '').strip()[:30]}'")
            skipped += 1
            continue

        email = row["Student's Email"].strip().lower()

        # Warn on duplicate email
        if email in duplicates:
            print(f"  ⚠️   Row {i:3d} DUPLICATE email '{email}' — overwriting row {duplicates[email]}")
        duplicates[email] = i

        name         = row["Your Full Name (Lastname Firstname Secondname)"].strip()
        enrollment   = clean_enrollment(row["Enrollment No."])
        if len(enrollment) < 5:
            print(f"  [!] Row {i:3d} WARNING: enrollment='{enrollment}' looks invalid for {email}")
        gender       = row["Gender"].strip().capitalize()
        blood_group  = clean_blood_group(row.get("Blood Group (Optional)", ""))
        student_mob  = clean_phone(row["Student's Phone Number (without +91)"])
        parent1_mob  = clean_phone(row["Parent's Mobile No. 1 (IT SHOULD BE CORRECT)"])
        parent2_mob  = clean_phone(row.get("Parent's Mobile No. 2 (IT SHOULD BE CORRECT)", ""))
        institute    = row["Institute"].strip()
        program      = row["Program (e.g B. Tech)"].strip()
        department   = row["Department (e.g CSE, IT)"].strip()
        hostel_raw   = row["Hostel"].strip()
        floor_raw    = row["Floor"].strip()
        room_raw     = row["Room No."].strip()

        # Derived fields
        category     = canonicalize_category(institute, program)
        hostel       = canonicalize_hostel(hostel_raw)
        hostel_code  = HOSTEL_CODES.get(hostel, hostel_raw)
        branch       = canonicalize_branch(department, category)

        doc_data = {
            "name":           name,
            "email":          email,
            "enrollmentNo":   enrollment,
            "gender":         gender,
            "bloodGroup":     blood_group,
            "mobile":         student_mob,
            "fatherMobile":   parent1_mob,
            "motherMobile":   parent2_mob,
            "institute":      institute,
            "program":        program,
            "department":     department,
            "category":       category,
            "branch":         branch,
            "hostel":         hostel,
            "assignedHostel": hostel_code,
            "floor":          floor_raw,
            "room":           room_raw,
            "year":           "",           # not in form — can be set by admin later
            "importedAt":     firestore.SERVER_TIMESTAMP,
        }

        ref = db.collection("student_imports").document(email)
        batch.set(ref, doc_data)
        batch_count += 1
        uploaded += 1

        print(f"  ✅  Row {i:3d} → {email[:40]:40s} | {hostel_code} | {branch[:35]}")

        # Commit in batches
        if batch_count >= BATCH_SIZE:
            batch.commit()
            batch = db.batch()
            batch_count = 0
            print(f"\n  🔥  Batch committed ({BATCH_SIZE} docs)\n")

    # Final commit
    if batch_count > 0:
        batch.commit()
        print(f"\n  🔥  Final batch committed ({batch_count} docs)\n")

    print("\n" + "="*60)
    print(f"✅  DONE!")
    print(f"   Uploaded : {uploaded}")
    print(f"   Skipped  : {skipped}")
    print(f"   Total    : {uploaded + skipped}")
    print("="*60)
    print("\n📱 Students can now sign up using their Gmail in the app.")


if __name__ == "__main__":
    main()
