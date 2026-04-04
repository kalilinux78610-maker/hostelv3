<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white" />
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
<img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white" />

<br/><br/>

# 🏠 HostelV3 — Smart Hostel Management System

### A complete, cloud-based hostel management platform for engineering colleges.
### Replaces all paper-based workflows with a real-time mobile application.

<br/>

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/kalilinux78610-maker/Hostel_App)
[![License](https://img.shields.io/badge/license-Private-red.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [User Roles](#-user-roles)
- [App Flow](#-app-flow)
- [Notification Chain](#-notification-chain)
- [Firestore Schema](#-firestore-schema)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**HostelV3** is a production-ready Flutter application that digitizes all hostel management workflows for engineering colleges. From leave approvals and gate passes to mess menus and complaint tracking — everything is handled in one app, in real time.

> ⚡ Built for scale: handles 100 to 100,000+ students with zero server management.

### Problems Solved

| ❌ Old Way | ✅ HostelV3 Way |
|-----------|----------------|
| Students hand-write leave forms | Digital application in 30 seconds |
| Warden manually signs papers | One-tap approve with instant notifications |
| No visibility of who is outside | Live "Out Now" list + gate scan tracking |
| Mess menu on a whiteboard | Dynamic weekly menu with meal photos |
| Complaints in a register | Digital tickets with real-time status |
| Attendance in Excel sheets | Cloud attendance with leave-aware sync |
| WhatsApp-based communication | Structured in-app push notifications |

---

## ✨ Key Features

### 🎓 For Students
- Apply **Home Leave** or **Outing** requests digitally
- Track approval status at every stage (HOD → Warden → Rector)
- View **digital QR gate pass** on final approval
- Real-time **push notification** at every step
- Browse **weekly mess menu** with meal photos
- File and track **complaints**
- View attendance and leave history

### 👨‍💼 For HOD
- See all pending leave requests from own department
- One-tap **Approve / Reject** with notification to student and warden
- View request history and statistics

### 🏠 For Warden
- See HOD-approved requests filtered by assigned hostel
- Approve/Reject with full student details
- Monitor who is currently **Out** from the hostel
- Manage hostel-level complaints

### 🏛️ For Rector
- Final approval authority for all requests
- Handle **Outing** requests directly (HOD/Warden bypassed)
- View live Out-Now lists across all hostels
- Access full student directory
- View reports and analytics

### 🔍 For Gate Guard
- **QR code scanner** to verify gate passes
- Mark students as **Out** / **Returned**
- View scan history

### 🍳 For Mess Manager
- Update weekly menu with **text + photos** per meal
- **Auto-reset prompt** every new week
- Changes reflected instantly for all students

### 🔧 For Admin
- Full system access
- **Bulk import** students via CSV
- Manage all staff roles
- View real-time activity feed
- Room availability management
- Reports and analytics

---

## 🛠 Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Mobile App** | Flutter (Dart) | Cross-platform iOS & Android |
| **Database** | Cloud Firestore | Real-time NoSQL database |
| **Authentication** | Firebase Auth (Google SSO) | Secure role-based login |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Real-time alerts |
| **Image Storage** | Cloudinary CDN | Profile & meal photos |
| **QR Code** | flutter_barcode_scanner | Gate pass scanning |
| **State Management** | StreamBuilder + setState | Real-time UI sync |

---

## 👥 User Roles

```
Login (Google SSO)
        │
        ▼
   RoleChecker  ──── Reads 'role' field from Firestore users collection
        │
   ┌────┴──────────────────────────────────────────────────┐
   │                                                        │
student  hod   warden   rector   guard   mess_manager   admin
```

| Role | Description | Key Permissions |
|------|-------------|----------------|
| `student` | Hostel resident | Apply leave, view status, complaints, mess menu |
| `hod` | Head of Department | Approve/reject student leave requests |
| `warden` | Hostel Warden | Approve HOD-cleared requests, manage hostel |
| `rector` | Director / Rector | Final approval, outing requests, full oversight |
| `guard` | Gate Security | Scan QR gate passes, mark in/out |
| `mess_manager` | Mess In-charge | Update weekly menu with photos |
| `admin` | System Administrator | Full access, import data, manage staff |

---

## 🔄 App Flow

### Home Leave Approval Chain
```
Student Applies
      │
      ▼
  HOD Reviews ──── Reject? → Student Notified ❌
      │ Approve ✅
      ▼
Warden Reviews ──── Reject? → Student Notified ❌
      │ Approve ✅
      ▼
Rector Reviews ──── Reject? → Student Notified ❌
      │ Approve ✅
      ▼
Gate Pass Generated (QR Code)
      │
      ▼
Guard Scans QR → Student marked "Out"
      │
      ▼
Student Returns → Guard Scans Again → "Returned"
```

### Outing Flow (Simplified)
```
Student → Direct to Rector → Approve/Reject → Gate Pass → Guard Scan
```

### Mess Menu Flow
```
Mess Manager → Upload text + photo per meal → Save to Firestore
                                                     │
                                        Students see live update instantly
```

---

## 🔔 Notification Chain

| Event | Who Gets Notified | Message |
|-------|-------------------|---------|
| Student submits Home Leave | HOD | "New Leave Request from [Name]" |
| Student submits Home Leave | Student | "Request Submitted ✅ — Pending HOD" |
| Student submits Outing | Rector | "New Outing Request from [Name]" |
| HOD approves | Student | "HOD Approved ✅ — Pending Warden" |
| HOD approves | Warden | "HOD approved [Name]'s request" |
| HOD rejects | Student | "HOD Rejected ❌" |
| Warden approves | Student | "Warden Approved ✅ — Pending Rector" |
| Warden approves | Rector | "New Approval Required" |
| Warden rejects | Student | "Warden Rejected ❌" |
| Rector approves | Student | "Approved 🎉 Gate pass ready!" |
| Rector rejects | Student | "Rector Rejected ❌" |

---

## 🗃 Firestore Schema

### `users/{uid}`
```json
{
  "name": "Rahul Sharma",
  "email": "rahul@college.ac.in",
  "role": "student",
  "assignedHostel": "BH1",
  "room": "204",
  "branch": "Computer Science Engineering",
  "category": "B.Tech",
  "year": "3rd",
  "parentContact": "9876543210",
  "feeStatus": "paid",
  "profileImageUrl": "https://res.cloudinary.com/...",
  "fcmToken": "FCM_TOKEN_HERE",
  "createdAt": "Timestamp"
}
```

### `leave_requests/{docId}`
```json
{
  "uid": "STUDENT_UID",
  "name": "Rahul Sharma",
  "email": "rahul@college.ac.in",
  "hostelId": "BH1",
  "room": "204",
  "branch": "Computer Science Engineering",
  "category": "B.Tech",
  "type": "Home Leave",
  "startDate": "Timestamp",
  "endDate": "Timestamp",
  "reason": "Family function",
  "status": "pending",
  "hodStatus": "approved",
  "wardenStatus": "pending",
  "rectorStatus": "waiting_for_warden",
  "createdAt": "Timestamp"
}
```

### `notifications/{docId}`
```json
{
  "title": "HOD Approved ✅",
  "message": "Your request is now pending Warden approval.",
  "receiverUid": "STUDENT_UID",
  "type": "leave_request",
  "relatedRequestId": "REQUEST_DOC_ID",
  "isRead": false,
  "createdAt": "Timestamp"
}
```

### `config/mess_menu`
```json
{
  "weekKey": "2026_W14",
  "Monday": {
    "Breakfast": "Idli, Sambar, Chutney",
    "Breakfast_imageUrl": "https://res.cloudinary.com/...",
    "Lunch": "Rice, Dal, Sabji, Roti",
    "Lunch_imageUrl": "https://res.cloudinary.com/...",
    "Dinner": "Chapati, Paneer, Rice",
    "Dinner_imageUrl": "https://res.cloudinary.com/..."
  }
}
```

---

## 📁 Project Structure

```
hostelv3/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── auth_gate.dart                 # Auth state listener
│   ├── role_checker.dart              # Role-based routing
│   ├── login_screen.dart              # Google SSO login
│   ├── home_screen.dart               # Loading/splash
│   │
│   ├── student_dashboard.dart         # Student home
│   ├── apply_leave_screen.dart        # Leave application form
│   ├── gate_pass_screen.dart          # QR gate pass
│   ├── notification_screen.dart       # In-app notifications
│   ├── mess_menu_screen.dart          # Student mess view
│   ├── student_profile_design_v2.dart # Student profile
│   ├── out_students_screen.dart       # Out-now list
│   │
│   ├── hod_dashboard.dart             # HOD approval panel
│   ├── hod_profile_screen.dart        # HOD profile
│   │
│   ├── warden_dashboard.dart          # Warden panel
│   │
│   ├── rector_dashboard.dart          # Rector panel
│   │
│   ├── guard_dashboard_screen.dart    # Guard home
│   ├── guard_scanner_screen.dart      # QR scanner
│   ├── guard_details_screen.dart      # Scanned pass detail
│   ├── guard_history_screen.dart      # Scan history
│   ├── guard_profile_screen.dart      # Guard profile
│   │
│   ├── mess/
│   │   ├── mess_manager_dashboard.dart  # Mess manager home
│   │   ├── mess_profile_screen.dart     # Mess manager profile
│   │
│   ├── mess_menu_editor_screen.dart   # Weekly menu editor with photos
│   │
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   └── tabs/
│   │       ├── student_directory_screen.dart
│   │       ├── student_detail_screen.dart
│   │       ├── bulk_import_screen.dart
│   │       ├── staff_management_screen.dart
│   │       ├── reports_tab.dart
│   │       ├── room_availability_screen.dart
│   │       ├── activity_feed_tab.dart
│   │       └── mess_management_screen.dart
│   │
│   ├── complaints/
│   │   ├── file_complaint_screen.dart
│   │   ├── student_complaints_screen.dart
│   │   └── admin_complaints_screen.dart
│   │
│   ├── attendance/
│   │   └── attendance_taking_screen.dart
│   │
│   ├── repositories/
│   │   ├── notification_repository.dart
│   │   ├── storage_repository.dart
│   │   ├── complaint_repository.dart
│   │   ├── mess_repository.dart
│   │   └── staff_repository.dart
│   │
│   ├── services/
│   │   ├── push_notification_service.dart
│   │   └── attendance_service.dart
│   │
│   ├── models/
│   └── utils/
│       └── canonical_names.dart
│
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / VS Code
- Firebase account
- Cloudinary account

### 1. Clone the Repository

```bash
git clone https://github.com/kalilinux78610-maker/Hostel_App.git
cd Hostel_App
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project
3. Enable **Authentication** → Google Sign-In
4. Enable **Cloud Firestore**
5. Enable **Cloud Messaging (FCM)**
6. Download `google-services.json` → place in `android/app/`
7. Download `GoogleService-Info.plist` → place in `ios/Runner/`
8. Update `lib/firebase_options.dart` with your config

### 4. Cloudinary Setup

1. Create account at [cloudinary.com](https://cloudinary.com)
2. Create an **unsigned upload preset**
3. Update in `lib/repositories/storage_repository.dart`:
```dart
final String cloudName = 'YOUR_CLOUD_NAME';
final String uploadPreset = 'YOUR_PRESET';
```

### 5. Run the App

```bash
flutter run
```

---

## ⚙️ Configuration

### Setting Up the First Admin / Rector

After the first user logs in with Google:

1. Go to Firebase Console → Firestore
2. Navigate to `users/{uid}`
3. Set `role` field to `"rector"` (or `"admin"`)
4. The user now has full access to manage the system

### Adding Staff via App

Once the Rector account is set up:
1. Login as Rector
2. Go to **Admin Panel → Staff Management**
3. Add staff by entering their Google email
4. Assign their role and hostel

### Importing Students

1. Login as Admin/Rector
2. Go to **Admin Panel → Bulk Import**
3. Upload CSV with columns: `name, email, hostel, room, branch, category, year`

---

## 🌐 Deployment

### Android (Play Store)

```bash
# Build release APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS (App Store)

```bash
flutter build ios --release
```

### Environment per College

For each new college deployment:
1. Create a new Firebase project
2. Update `google-services.json` and `GoogleService-Info.plist`
3. Update Cloudinary credentials
4. Build and deploy to Play Store / App Store

---

## 📸 Screenshots

> _Screenshots and demo GIFs coming soon_

| Student Dashboard | Leave Application | Gate Pass |
|:-----------------:|:-----------------:|:---------:|
| _(screenshot)_ | _(screenshot)_ | _(screenshot)_ |

| HOD Dashboard | Warden Panel | Rector Panel |
|:-------------:|:------------:|:------------:|
| _(screenshot)_ | _(screenshot)_ | _(screenshot)_ |

| Mess Menu | Guard Scanner | Admin Panel |
|:---------:|:-------------:|:-----------:|
| _(screenshot)_ | _(screenshot)_ | _(screenshot)_ |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is **privately licensed**. All rights reserved.

For licensing inquiries or institutional deployment, contact the author.

---

## 📬 Contact

**Developer:** [@kalilinux78610-maker](https://github.com/kalilinux78610-maker)

**Repository:** [github.com/kalilinux78610-maker/Hostel_App](https://github.com/kalilinux78610-maker/Hostel_App)

---

<div align="center">

### ⭐ If you find this useful, give it a star!

**Built with ❤️ using Flutter + Firebase**

</div>
