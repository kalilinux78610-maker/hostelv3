# 🏠 HostelLink — Project Progress Tracker

> **Project:** Hostel Management System
> **Tech Stack:** Flutter • Firebase Auth • Cloud Firestore • Firebase Storage • FCM • Riverpod
> **Repo:** https://github.com/kalilinux78610-maker/hostelv3.git
> **Started:** April 2026

---

## 👥 Team Members

| Name | Role | GitHub Handle |
|------|------|---------------|
| Karan | Lead Developer | kalilinux78610-maker |
| _(Partner)_ | Developer | _(add here)_ |

---

## 📋 Legend

| Symbol | Meaning |
|--------|---------|
| ✅ `[x]` | Completed |
| 🔄 `[~]` | In Progress |
| ❌ `[ ]` | Pending / Not Started |
| 🐛 | Bug |
| 📅 | Date completed |

> **Rule:** Jab bhi koi feature/bug complete karo → uska date aur naam yahan likho.

---

---

# 🗂️ MODULES OVERVIEW

| Module | Status | Files |
|--------|--------|-------|
| Auth / Login / Signup | ✅ Done | `login_screen.dart`, `signup_screen.dart`, `auth_gate.dart` |
| Role Checker (Routing) | ✅ Done | `role_checker.dart` |
| Student Dashboard | ✅ Done | `student_dashboard.dart` |
| Student Profile | ✅ Done | `student_profile_design_v2.dart` |
| Leave Request System | ✅ Done | `apply_leave_screen.dart` |
| Gate Pass / QR Code | ✅ Done | `gate_pass_screen.dart` |
| HOD Dashboard | ✅ Done | `hod_dashboard.dart` |
| HOD Profile | ✅ Done | `hod_profile_screen.dart` |
| Warden Dashboard | ✅ Done | `warden_dashboard.dart` |
| Rector Dashboard | ✅ Done | `rector_dashboard.dart` |
| Guard System | ✅ Done | `guard_dashboard_screen.dart` + related |
| Admin Dashboard | ✅ Done | `admin/admin_dashboard_screen.dart` |
| Mess Manager | 🔄 Partial | `mess/mess_manager_dashboard.dart` |
| Complaints System | 🔄 Partial | `features/complaints/` |
| Notifications | 🔄 Partial | `notification_screen.dart` |
| Attendance | ❌ Pending | `attendance/` |

---

---

# ✅ COMPLETED WORK (Detailed)

---

## 🔐 1. Authentication System

**Files:** `login_screen.dart`, `signup_screen.dart`, `auth_gate.dart`, `services/auth_service.dart`

- [x] Email/Password login *(Done)*
- [x] Student signup with enrollment validation *(Done)*
- [x] Firebase Auth integration *(Done)*
- [x] Auto-login via `auth_gate.dart` *(Done)*
- [x] FCM token saved on login *(Done)*
- [x] FCM token deleted on logout (`auth_service.dart`) *(Done)*
- [x] Centralized `AuthService.signOut()` *(Done)*
- [x] Role detection after login (`role_checker.dart`) *(Done)*

---

## 🗺️ 2. Role-Based Routing

**File:** `role_checker.dart`

- [x] Reads `role` field from Firestore `users` collection *(Done)*
- [x] Routes to correct dashboard:
  - `student` → Student Dashboard
  - `hod` → HOD Dashboard
  - `warden` → Warden Dashboard
  - `rector` → Rector Dashboard
  - `guard` → Guard Dashboard
  - `admin` → Admin Dashboard
  - `mess_manager` → Mess Manager Dashboard
- [x] Loading state while fetching role *(Done)*
- [x] Unknown role fallback with logout *(Done)*

---

## 🎓 3. Student Dashboard & Profile

**Files:** `student_dashboard.dart`, `student_profile_design_v2.dart`, `student_profile_screen.dart`

- [x] Bottom navigation bar (Home, Notifications, Profile) *(Done)*
- [x] Student home tab with hostel info *(Done)*
- [x] Leave request submission *(Done)*
- [x] Leave history with status badges *(Done)*
- [x] Gate pass QR code display *(Done)*
- [x] Profile photo (from Firebase Storage) *(Done)*
- [x] Edit name & phone number *(Done)*
- [x] View enrollment, hostel, room, branch info *(Done)*
- [x] **Logout confirmation dialog** — dark gradient popup 📅 16 Apr 2026 by Karan

---

## 📝 4. Leave Request System

**File:** `apply_leave_screen.dart`

- [x] Leave type selection (Home, Medical, Other) *(Done)*
- [x] Date range picker (From → To) *(Done)*
- [x] Reason text field *(Done)*
- [x] Submit to Firestore `leave_requests` collection *(Done)*
- [x] Student info auto-filled (name, room, hostel, branch) *(Done)*
- [x] Status tracking: `pending → warden approved → rector approved → approved` *(Done)*
- [x] Notification sent to warden on new request *(Done)*

---

## 🔑 5. Gate Pass / QR Code System

**File:** `gate_pass_screen.dart`

- [x] QR code generated for approved leave *(Done)*
- [x] QR code valid for entire leave duration *(Done)*
- [x] Two-step scan — Guard scans once for Check-Out, again for Check-In *(Done)*
- [x] QR expires automatically after leave end date *(Done)*
- [x] Status: `approved → checked_out → checked_in (completed)` *(Done)*

---

## 🧑‍💼 6. HOD Dashboard

**Files:** `hod_dashboard.dart`, `hod_profile_screen.dart`

- [x] View all pending leave requests *(Done)*
- [x] Approve / Reject with remarks *(Done)*
- [x] HOD profile page — view info *(Done)*
- [x] Notifications from students *(Done)*
- [x] **Logout dialog on power icon (header)** 📅 16 Apr 2026 by Karan
- [x] **Logout dialog on error-state fallback button** 📅 16 Apr 2026 by Karan

---

## 🏠 7. Warden Dashboard

**File:** `warden_dashboard.dart`

- [x] Department-wise leave request grid (Degree & Diploma toggle) *(Done)*
- [x] Multiple hostel support (dropdown selector) *(Done)*
- [x] Pending count badge on departments *(Done)*
- [x] Approve → forwards to Rector *(Done)*
- [x] Reject → student notified *(Done)*
- [x] Warden profile tab — edit name, phone, photo *(Done)*
- [x] Firebase Storage for profile photo *(Done)*
- [x] **Logout dialog on header power icon** 📅 16 Apr 2026 by Karan
- [x] **Logout dialog on profile logout button** 📅 16 Apr 2026 by Karan

---

## 🏛️ 8. Rector Dashboard

**File:** `rector_dashboard.dart`

- [x] Pending leave requests from Warden-approved list *(Done)*
- [x] Final Approve / Reject *(Done)*
- [x] Gate pass history (Check-In / Check-Out records) *(Done)*
- [x] Out-students live list *(Done)*
- [x] Profile tab with personal info *(Done)*
- [x] Broadcast message to students *(Done)*
- [x] Change password *(Done)*
- [x] About app dialog *(Done)*
- [x] Notification switch settings (UI only) *(Done)*
- [x] Delete gate pass history records *(Done)*
- [x] **Logout dialog on "Log Out" button** 📅 16 Apr 2026 by Karan

---

## 🛡️ 9. Guard System

**Files:** `guard_dashboard_screen.dart`, `guard_profile_screen.dart`, `guard_scanner_screen.dart`, `guard_verify_screen.dart`, `guard_details_screen.dart`, `guard_history_screen.dart`

- [x] Guard dashboard — scan QR & view out students *(Done)*
- [x] QR code scanner (camera) *(Done)*
- [x] Verify student gate pass *(Done)*
- [x] Mark as Checked Out (first scan) *(Done)*
- [x] Mark as Checked In (second scan) *(Done)*
- [x] Student details view from scan *(Done)*
- [x] History of all scans *(Done)*
- [x] Guard profile — edit name, phone, photo *(Done)*
- [x] **Logout dialog on "LOGOUT" button** 📅 16 Apr 2026 by Karan

---

## 🧑‍💻 10. Admin Dashboard

**Files:** `admin/admin_dashboard_screen.dart`, `admin/tabs/`

### Dashboard Tabs:
- [x] **Activity Feed Tab** — recent system activity (`activity_feed_tab.dart`) *(Done)*
- [x] **Student Directory Tab** — search/filter/view all students (`student_directory_screen.dart`) *(Done)*
  - [x] Student detail view (`student_detail_screen.dart`) *(Done)*
- [x] **Staff Management Tab** — add/view staff roles (`staff_management_screen.dart`) *(Done)*
- [x] **Reports Tab** — system reports (`reports_tab.dart`) *(Done)*
  - [x] Attendance reports screen (`attendance_reports_screen.dart`) *(Done)*
  - [x] Room availability screen (`room_availability_screen.dart`) *(Done)*
  - [x] Mess management screen (`mess_management_screen.dart`) *(Done)*
- [x] **Bulk Import Tab** — CSV student import (`bulk_import_screen.dart`) *(Done)*
- [x] **Logout dialog on AppBar logout icon** 📅 16 Apr 2026 by Karan
- [x] **Import tab bottom overflow fix** 📅 16 Apr 2026 by Karan

### Bulk Import Features:
- [x] CSV file picker *(Done)*
- [x] 13-column new format + 7-column old format *(Done)*
- [x] Batch write to `student_imports` Firestore collection *(Done)*
- [x] Auto-sync already-registered student profiles *(Done)*
- [x] Generate 300 demo students *(Done)*
- [x] Promote `rector@demo.com` button *(Done)*
- [x] Delete all students button *(Done)*
- [x] Clear all leave requests & complaints button *(Done)*

---

## 🍽️ 11. Mess System

**Files:** `mess/mess_manager_dashboard.dart`, `mess/mess_profile_screen.dart`, `mess_menu_screen.dart`, `mess_menu_editor_screen.dart`, `student_mess_screen.dart`

- [x] Mess manager dashboard *(Done — basic)*
- [x] Mess profile screen *(Done)*
- [x] Mess menu display (student view) *(Done)*
- [x] Mess menu editor (manager can update menu) *(Done)*
- [ ] Meal attendance tracking *(Pending)*
- [ ] Mess fee management *(Pending)*

---

## 💬 12. Complaints System

**Files:** `features/complaints/`

- [x] Student can submit complaint *(Done)*
- [x] Admin/Warden can view complaints *(Done)*
- [x] Complaint status tracking *(Done)*
- [ ] Complaint resolution remarks *(Pending)*
- [ ] Complaint categories *(Pending)*

---

## 🔔 13. Notifications System

**File:** `notification_screen.dart`, `repositories/notification_repository.dart`

- [x] Notification list screen *(Done)*
- [x] Send notification on leave approval/rejection *(Done)*
- [x] Warden notified on new leave request *(Done)*
- [x] Rector notified when warden approves *(Done)*
- [x] FCM token management *(Done)*
- [ ] Notification badge count *(Pending)*
- [ ] Mark as read *(Pending)*
- [ ] Deep link on notification tap *(Pending)*

---

## 🎨 14. UI / Design System

- [x] Dark navy primary theme (`#002244`) *(Done)*
- [x] Custom `HeaderClipper` curved banner in Guard & Warden profile *(Done)*
- [x] **Unified Logout Confirmation Dialog** (ALL 6 roles) 📅 16 Apr 2026 by Karan
  - Design: `#1a1a2e → #16213e → #0f3460` gradient
  - Red-bordered icon (clean, no blur)
  - Cancel button — glassmorphism style
  - Log Out button — `#FF416C → #FF4B2B` gradient
- [x] Role badge chips on profile pages *(Done)*
- [x] Floating avatar in profile headers *(Done)*

---

---

# 🔄 IN PROGRESS

- [~] `PROJECT_PROGRESS.md` — being maintained & updated continuously
- [~] Pending git push for admin logout + import fix + this file

---

---

# ❌ PENDING / TODO

## High Priority
- [ ] Push all unpushed changes to GitHub
- [ ] Notification badge count on dashboard icons
- [ ] Mark notifications as read
- [ ] Mess manager logout dialog (check `mess_profile_screen.dart`)

## Medium Priority
- [ ] HOD — no dedicated profile photo upload yet
- [ ] Rector profile photo upload
- [ ] Complaint resolution remarks from admin/warden
- [ ] Export reports as PDF (Admin Reports tab)

## Low Priority / Future
- [ ] Room allocation management panel (Admin)
- [ ] Floor-wise student list view
- [ ] Hostel occupancy stats/chart
- [ ] Dark mode support
- [ ] Multi-language (Hindi + English)
- [ ] App version & update check
- [ ] Meal attendance (Mess module)
- [ ] Mess fee management

---

---

# 🐛 BUG TRACKER

| # | Bug Description | Status | Fixed By | Date |
|---|----------------|--------|----------|------|
| 1 | Import tab — bottom overflow by 45px | ✅ Fixed | Karan | 16 Apr 2026 |
| 2 | Warden power button: `_buildLogoutDialog` called from wrong class (`_WardenHomeTabState`) | ✅ Fixed | Karan | 16 Apr 2026 |
| 3 | Student logout dialog — broken bracket structure in "Log Out" Text widget | ✅ Fixed | Karan | 16 Apr 2026 |
| 4 | Package version conflicts (minor warnings) | 🔄 Monitoring | - | - |

---

---

# 📦 GIT COMMIT LOG

| Date | Commit Message | By |
|------|---------------|-----|
| 16 Apr 2026 | `chore: initial project setup — Flutter + Firebase` | Karan |
| 16 Apr 2026 | `feat: gate pass QR two-step check-in/check-out` | Karan |
| 16 Apr 2026 | `feat: Add logout confirmation dialog to all profiles (Student, HOD, Warden, Rector, Guard)` | Karan |
| 16 Apr 2026 | `feat: admin logout dialog + fix import tab overflow + add PROJECT_PROGRESS.md` | Karan *(pending)* |

---

---

# 📁 Full File Reference Map

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase config
├── app_config.dart                    # App-level config
├── auth_gate.dart                     # Auth state listener
├── role_checker.dart                  # Post-login role routing
├── home_screen.dart                   # Simple logout screen
├── login_screen.dart                  # Login UI
├── signup_screen.dart                 # Signup UI
│
├── student_dashboard.dart             # Student main dashboard
├── student_profile_design_v2.dart     # Student profile + logout dialog ✅
├── student_profile_screen.dart        # Older student profile (unused?)
├── apply_leave_screen.dart            # Leave request form
├── gate_pass_screen.dart              # QR gate pass
├── student_mess_screen.dart           # Student mess menu view
├── out_students_screen.dart           # Live out-students list
├── notification_screen.dart           # Notifications list
│
├── hod_dashboard.dart                 # HOD dashboard + logout dialog ✅
├── hod_profile_screen.dart            # HOD profile
│
├── warden_dashboard.dart              # Warden dashboard + logout dialog ✅
│
├── rector_dashboard.dart              # Rector dashboard + logout dialog ✅
│
├── guard_dashboard_screen.dart        # Guard main screen
├── guard_profile_screen.dart          # Guard profile + logout dialog ✅
├── guard_scanner_screen.dart          # QR scanner
├── guard_verify_screen.dart           # QR verify & check-in/out
├── guard_details_screen.dart          # Student details on scan
├── guard_history_screen.dart          # Scan history
│
├── mess_menu_screen.dart              # Mess menu display
├── mess_menu_editor_screen.dart       # Mess manager menu editor
│
├── admin/
│   ├── admin_dashboard_screen.dart    # Admin dashboard + logout dialog ✅
│   └── tabs/
│       ├── activity_feed_tab.dart     # Activity feed
│       ├── student_directory_screen.dart  # Student directory
│       ├── student_detail_screen.dart     # Student detail
│       ├── staff_management_screen.dart   # Staff management
│       ├── reports_tab.dart               # Reports
│       ├── attendance_reports_screen.dart # Attendance reports
│       ├── room_availability_screen.dart  # Room availability
│       ├── mess_management_screen.dart    # Mess management
│       └── bulk_import_screen.dart        # CSV bulk import ✅ (overflow fixed)
│
├── mess/
│   ├── mess_manager_dashboard.dart    # Mess manager dashboard
│   └── mess_profile_screen.dart       # Mess manager profile
│
├── features/
│   └── complaints/                    # Complaints module
│
├── attendance/                        # Attendance module (pending)
│
├── services/
│   └── auth_service.dart             # Centralized auth + FCM cleanup
│
├── repositories/
│   └── notification_repository.dart  # Notification sender
│
├── models/                           # Data models
├── utils/                            # Utility functions (canonical_names, etc.)
└── core/                             # Core widgets/helpers
```

---

> 📌 **Team Note:** Is file ko project root mein rakha gaya hai (`PROJECT_PROGRESS.md`).
> Har kaam complete hone ke baad yahan update karo — date aur naam ke saath.
> Naye bugs ko Bug Tracker table mein add karo.
> Naye commits ko Git Log mein add karo.
