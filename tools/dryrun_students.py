"""
DRY RUN — validates CSV data WITHOUT uploading to Firestore.
Usage: python dryrun_students.py
"""

import csv
import re
import os
import sys

# ─── Import helpers from the main script ─────────────────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)
from import_students import (
    is_valid_row, canonicalize_category, canonicalize_hostel,
    canonicalize_branch, clean_phone, clean_enrollment, clean_blood_group,
    HOSTEL_CODES
)

CSV_PATH = r"C:\Users\Nanu\AppData\Local\Packages\5319275A.WhatsAppDesktop_cv1g1gvanyjgm\LocalState\sessions\E79F38775CD0D0A54719202FC41AEE0FCA35A9CF\transfers\2026-19\Hostel Student List - Form Responses 1 (1).csv"

def main():
    if not os.path.exists(CSV_PATH):
        print(f"❌  CSV not found: {CSV_PATH}")
        sys.exit(1)

    with open(CSV_PATH, newline='', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"{'='*70}")
    print(f"  DRY RUN — {len(rows)} rows found in CSV")
    print(f"{'='*70}\n")

    valid      = []
    invalid    = []
    duplicates = {}
    emails_seen = {}

    for i, row in enumerate(rows, start=2):
        if not is_valid_row(row):
            reason = "bad email" if "@" not in row.get("Student's Email","") else \
                     "no name" if len(row.get("Your Full Name (Lastname Firstname Secondname)","").strip()) < 3 else \
                     "bad enrollment"
            invalid.append((i, row, reason))
            continue

        email      = row["Student's Email"].strip().lower()
        name       = row["Your Full Name (Lastname Firstname Secondname)"].strip()
        enrollment = clean_enrollment(row["Enrollment No."])
        institute  = row["Institute"].strip()
        program    = row["Program (e.g B. Tech)"].strip()
        dept       = row["Department (e.g CSE, IT)"].strip()
        hostel_raw = row["Hostel"].strip()
        category   = canonicalize_category(institute, program)
        hostel     = canonicalize_hostel(hostel_raw)
        hostel_code= HOSTEL_CODES.get(hostel, f"⚠️ UNKNOWN ({hostel_raw})")
        branch     = canonicalize_branch(dept, category)

        # Duplicate check
        dup_flag = ""
        if email in emails_seen:
            dup_flag = f"  ⚠️  DUPLICATE (first seen row {emails_seen[email]})"
        emails_seen[email] = i

        valid.append({
            "row":         i,
            "email":       email,
            "name":        name,
            "enrollment":  enrollment,
            "category":    category,
            "hostel_code": hostel_code,
            "branch":      branch,
            "dup":         dup_flag,
        })

    # ── Print invalid rows ────────────────────────────────────────────────────
    if invalid:
        print(f"⛔  INVALID ROWS ({len(invalid)} skipped):")
        for row_num, row, reason in invalid:
            name = row.get("Your Full Name (Lastname Firstname Secondname)", "")[:40]
            email = row.get("Student's Email", "")[:40]
            print(f"    Row {row_num:3d} — [{reason}] name='{name}' email='{email}'")
        print()

    # ── Print valid rows ──────────────────────────────────────────────────────
    print(f"✅  VALID ROWS ({len(valid)} will be uploaded):\n")
    print(f"  {'Row':>3}  {'Email':<40}  {'Enrol':<12}  {'Cat':<7}  {'Hostel':<5}  Branch")
    print(f"  {'-'*3}  {'-'*40}  {'-'*12}  {'-'*7}  {'-'*5}  {'-'*35}")
    for v in valid:
        dup = v["dup"]
        print(f"  {v['row']:3d}  {v['email']:<40}  {v['enrollment']:<12}  "
              f"{v['category']:<7}  {v['hostel_code']:<5}  {v['branch'][:35]}{dup}")

    # ── Summary ───────────────────────────────────────────────────────────────
    print(f"\n{'='*70}")
    print(f"  SUMMARY")
    print(f"  Total rows  : {len(rows)}")
    print(f"  Valid       : {len(valid)}")
    print(f"  Skipped     : {len(invalid)}")
    dups = sum(1 for v in valid if v["dup"])
    print(f"  Duplicates  : {dups}  (will be overwritten — last row wins)")
    unkn = sum(1 for v in valid if "UNKNOWN" in v["hostel_code"])
    print(f"  Unknown hostels: {unkn}")
    print(f"{'='*70}")
    print("\n✅  If above looks correct, run:  python import_students.py")


if __name__ == "__main__":
    main()
