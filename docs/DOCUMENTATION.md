# HostelV3 — Complete Product Documentation
### Cloud-Based Hostel Management System
**Version 1.0 | Built with Flutter + Firebase**

---

## Table of Contents
1. [Product Overview](#1-product-overview)
2. [Technology Stack](#2-technology-stack)
3. [User Roles & Access Control](#3-user-roles--access-control)
4. [System Architecture](#4-system-architecture)
5. [Feature Modules](#5-feature-modules)
6. [Complete User Flows](#6-complete-user-flows)
7. [Notification Flow (Full Chain)](#7-notification-flow-full-chain)
8. [Firestore Database Schema](#8-firestore-database-schema)
9. [File & Image Storage](#9-file--image-storage)
10. [Deployment Guide (New College Setup)](#10-deployment-guide-new-college-setup)
11. [Security & Access Rules](#11-security--access-rules)
12. [Pricing & Licensing](#12-pricing--licensing)

---

## 1. Product Overview

**HostelV3** is a fully digital hostel management platform designed for engineering colleges and universities. It replaces all paper-based and WhatsApp-based hostel workflows with a secure, real-time, cloud-connected mobile application.

### Problems it solves
| Old Way | HostelV3 Way |
|---------|-------------|
| Students hand-write leave forms | Students apply digitally in 30 seconds |
| Warden signs paper manually | One-tap approve/reject with instant notifications |
| No visibility into who is "out" | Live gate pass scanning & real-time "Out Now" list |
| Mess menu on a whiteboard | Dynamic weekly menu with meal photos |
| Complaints in a register | Digital complaint tickets with status tracking |
| Attendance in Excel | Cloud attendance with leave-aware auto-sync |
| No parent visibility | Notifications traceable to every step |

---

## 2. Technology Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) — iOS + Android |
| Backend | Firebase (Google Cloud) |
| Database | Cloud Firestore (NoSQL, real-time) |
| Authentication | Firebase Authentication (Google SSO) |
| Image Storage | Cloudinary CDN |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| QR Code | Mobile camera scanner (flutter_barcode_scanner) |

### Why Firebase?
- Real-time sync — changes appear instantly on all devices
- No server maintenance required
- Scales from 100 to 100,000 students automatically
- 99.99% uptime SLA

---

## 3. User Roles & Access Control

The app uses **role-based access control (RBAC)**. Every user has a `role` field in Firestore which determines their dashboard.

```
Login (Google SSO)
        │
        ▼
   RoleChecker
        │
   ┌────┴─────────────────────────────────────────┐
   │                                               │
student  hod   warden   rector   guard   mess_manager   admin
   │      │       │        │       │          │           │
Student HOD   Warden  Rector  Guard    Mess       Admin
Dash   Dash    Dash    Dash   Dash   Manager    Dashboard
                                               Dash
```

### Role Summary

| Role | Who | Dashboard |
|------|-----|-----------|
| `student` | Hostel resident | Apply leave, view status, complaints, mess menu, notifications |
| `hod` | Head of Department | Approve/reject student leave requests |
| `warden` | Hostel Warden | Approve/reject HOD-cleared requests, manage hostel |
| `rector` | Rector / Director | Final approval, outing requests, manage all students |
| `guard` | Gate Guard | Scan QR gate passes, mark students in/out |
| `mess_manager` | Mess In-charge | Update weekly menu with photos |
| `admin` | System Admin | Full access — all data, student import, staff management |

> **Note:** Role assignment is done by the Rector/Admin from the admin panel. New users who sign up with Google see a "Pending Approval" screen until a role is assigned.

---

## 4. System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                   │
│                                                          │
│  Student   HOD    Warden   Rector   Guard   Mess   Admin │
│  App       App    App      App      App     App    App   │
└──────────────────────────┬───────────────────────────────┘
                           │ HTTPS / WebSocket
                           ▼
┌──────────────────────────────────────────────────────────┐
│                   FIREBASE PLATFORM                       │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  Firestore   │  │    Auth      │  │     FCM       │  │
│  │  (Database)  │  │  (Google SSO)│  │ (Push Notifs) │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                   CLOUDINARY CDN                          │
│            (Profile photos, Meal photos)                 │
└──────────────────────────────────────────────────────────┘
```

---

## 5. Feature Modules

### 5.1 Authentication Module
- **Google Single Sign-On** — no passwords to remember
- **Auto role detection** on every login
- **Pending Approval** screen for unassigned users
- **FCM token** saved on login for push notifications

---

### 5.2 Leave Management Module
The core module of the app. Handles two types of requests:

#### Leave Types
| Type | Flow | Approvers |
|------|------|-----------|
| **Home Leave** | Multi-step | HOD → Warden → Rector |
| **Outing** | Direct | Rector only |

#### Student Side
- Select leave type (Home / Outing)
- Choose start date + end date + time
- Enter reason
- Submit → instant notification to first approver
- Track status in real-time (Pending → HOD Approved → Warden Approved → Rector Approved)

#### Approval Side
- Each approver sees only their pending requests
- One-tap Approve or Reject with a reason
- Every action triggers cascading notifications

#### Gate Pass
- On final Rector approval, a **digital QR gate pass** is generated
- Student shows QR at gate
- Guard scans it to mark student as **"Out"**
- When student returns, guard scans again to mark **"Returned"**

---

### 5.3 Notification Module
- **In-app notifications** stored in Firestore
- **Push notifications** via FCM (even when app is closed)
- **Role-based delivery** — each notification goes to the exact right person
- **Read/Unread** status tracking
- **Real-time stream** — bell icon badge updates live

---

### 5.4 Mess Menu Module
- **Weekly schedule** (Monday–Sunday)
- **Three meals** per day: Breakfast, Lunch, Dinner
- **Meal photos** — Mess Manager can upload photos from camera or gallery
- **Auto-reset** — prompts reset at start of every new week
- **Student view** — live, photo-first menu cards
- **Cloud storage** — photos on Cloudinary, URLs in Firestore

---

### 5.5 Complaints Module
- Students file complaints with category, description, and optional photo
- Complaints assigned to Warden/Admin
- Status tracking: Open → In Progress → Resolved
- Admin can respond and close tickets

---

### 5.6 Attendance Module
- Wardens/Rectors take daily hostel attendance
- Leave-aware: students who are officially "out" are automatically excluded
- Attendance history viewable by Admin/Rector
- Notifications sent to students marked absent

---

### 5.7 Student Directory Module (Admin/Rector)
- Full searchable list of all students
- Filter by hostel, branch, category, year
- View individual student profile with full history
- Export-ready data structure

---

### 5.8 Bulk Import Module (Admin)
- Import students via CSV/Excel format
- Pre-register email IDs so students can login with Google
- Auto-assign hostel, room, branch, year on first login

---

### 5.9 Staff Management Module (Admin)
- Add/remove HODs, Wardens, Guards, Mess Managers
- Assign roles directly from the admin panel
- Profile management for all staff

---

### 5.10 Reports Module (Admin/Rector)
- Leave request statistics
- Attendance summaries
- Activity feed — real-time log of all recent actions
- Room availability overview

---

### 5.11 Guard Module
- QR code camera scanner
- See who is approved to exit
- Mark students Out / Returned
- View scan history

---

## 6. Complete User Flows

### 6.1 Student Leave Application Flow

```
Student Opens App
        │
        ▼
Student Dashboard → "Apply Leave" button
        │
        ▼
Select Type: Home Leave OR Outing
        │
  ┌─────┴─────┐
  │           │
Home        Outing
Leave       Request
  │           │
Choose      Choose
Dates       Date/Time
  │           │
Enter       Enter
Reason      Reason
  │           │
Submit      Submit
  │           │
  └─────┬─────┘
        │
        ▼
Firestore: leave_requests created
        │
        ▼
Notification sent to First Approver
        │
Student sees "Pending" status in dashboard
```

---

### 6.2 Home Leave Approval Chain

```
┌─────────────────────────────────────────────────────────┐
│ STEP 1: HOD REVIEW                                      │
│                                                         │
│  HOD gets push notification                             │
│  HOD opens app → sees request in queue                  │
│  HOD taps Approve/Reject                                │
│                                                         │
│  IF APPROVED:                                           │
│    → wardenStatus = 'pending'                           │
│    → Student notified: "HOD Approved ✅"                │
│    → Warden notified: "New request from [name]"         │
│                                                         │
│  IF REJECTED:                                           │
│    → status = 'rejected'                                │
│    → Student notified: "HOD Rejected ❌"                │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼ (if approved)
┌─────────────────────────────────────────────────────────┐
│ STEP 2: WARDEN REVIEW                                   │
│                                                         │
│  Warden gets push notification                          │
│  Warden taps request → sees full details                │
│  Warden taps Approve/Reject                             │
│                                                         │
│  IF APPROVED:                                           │
│    → rectorStatus = 'pending'                           │
│    → Student notified: "Warden Approved ✅"             │
│    → Rector notified: "New approval required"           │
│                                                         │
│  IF REJECTED:                                           │
│    → status = 'rejected'                                │
│    → Student notified: "Warden Rejected ❌"             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼ (if approved)
┌─────────────────────────────────────────────────────────┐
│ STEP 3: RECTOR FINAL APPROVAL                           │
│                                                         │
│  Rector gets push notification                          │
│  Rector sees request → Approve/Reject                   │
│                                                         │
│  IF APPROVED:                                           │
│    → status = 'approved'                                │
│    → Student notified: "Approved! Gate pass ready 🎉"   │
│    → Digital QR gate pass generated                     │
│                                                         │
│  IF REJECTED:                                           │
│    → status = 'rejected'                                │
│    → Student notified: "Rector Rejected ❌"             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼ (if approved)
┌─────────────────────────────────────────────────────────┐
│ STEP 4: GATE EXIT                                       │
│                                                         │
│  Student shows QR code at gate                          │
│  Guard scans QR → Student marked "Out"                  │
│  Student returns → Guard scans again → "Returned"       │
│  Attendance auto-updated                                │
└─────────────────────────────────────────────────────────┘
```

---

### 6.3 Outing Flow (Simplified)
```
Student → Apply Outing → Rector Queue → Rector Approve/Reject → Gate Pass → Guard Scan
```
> HOD and Warden are bypassed for outings.

---

### 6.4 Mess Menu Update Flow
```
Mess Manager opens app
          │
          ▼
Mess Manager Dashboard → "Edit Menu" tab
          │
          ▼
Select day tab (Mon–Sun)
          │
          ▼
For each meal (Breakfast / Lunch / Dinner):
  → Type food items in text field
  → Tap "Add Photo" → choose camera or gallery
  → Photo uploads to Cloudinary
  → URL saved instantly to Firestore
          │
          ▼
Tap "Save Menu to Cloud"
          │
          ▼
Students open app → see updated menu with photos in real-time
```

---

### 6.5 Complaint Flow
```
Student → File Complaint (category + description + optional photo)
        → Firestore: complaints collection
        → Warden/Admin notified
        → Admin reviews → updates status
        → Student sees status change in-app
```

---

### 6.6 New College Onboarding Flow
```
1. Admin creates Firebase project for college
2. Configure google-services.json with college Firebase credentials
3. Build & deploy app to Play Store / App Store
4. Rector account created first (manually set role = 'rector' in Firestore)
5. Rector logs in → Admin panel available
6. Rector/Admin bulk imports student list (CSV)
7. Rector adds staff (HODs, Wardens, Guards, Mess Manager)
8. Assign hostels to wardens
9. Students log in with Google → auto-matched to their pre-registered email
10. System is live!
```

---

## 7. Notification Flow (Full Chain)

| Trigger | Sender | Receiver | Message |
|---------|--------|----------|---------|
| Student submits leave | System | HOD | "New Leave Request from [Name]" |
| Student submits leave | System | Student | "Request Submitted ✅ — Pending HOD" |
| Student submits outing | System | Rector | "New Outing Request from [Name]" |
| HOD approves | System | Student | "HOD Approved ✅ — Pending Warden" |
| HOD approves | System | Warden | "HOD approved [Name]'s request" |
| HOD rejects | System | Student | "HOD Rejected ❌" |
| Warden approves | System | Student | "Warden Approved ✅ — Pending Rector" |
| Warden approves | System | Rector | "New Approval Required from [Name]" |
| Warden rejects | System | Student | "Warden Rejected ❌" |
| Rector approves | System | Student | "Approved 🎉 — Gate pass ready" |
| Rector rejects | System | Student | "Rector Rejected ❌" |
| Complaint filed | System | Warden | "New Complaint Filed" |
| Complaint resolved | System | Student | "Your complaint was resolved" |
| Attendance marked absent | System | Student | "You were marked absent today" |

---

## 8. Firestore Database Schema

### Collection: `users`
```
users/{uid}
  ├── name: string
  ├── email: string
  ├── role: string           // 'student' | 'hod' | 'warden' | 'rector' | 'guard' | 'mess_manager' | 'admin'
  ├── assignedHostel: string // e.g. 'BH1', 'GH2'
  ├── room: string
  ├── branch: string
  ├── category: string       // 'B.Tech' | 'M.Tech' etc.
  ├── year: string
  ├── parentContact: string
  ├── feeStatus: string      // 'paid' | 'unpaid'
  ├── profileImageUrl: string
  ├── fcmToken: string       // For push notifications
  └── createdAt: timestamp
```

### Collection: `leave_requests`
```
leave_requests/{docId}
  ├── uid: string            // Student's Firebase UID
  ├── name: string
  ├── email: string
  ├── hostelId: string
  ├── room: string
  ├── branch: string
  ├── category: string
  ├── type: string           // 'Home Leave' | 'Outing'
  ├── startDate: timestamp
  ├── endDate: timestamp
  ├── reason: string
  ├── status: string         // 'pending' | 'approved' | 'rejected' | 'out' | 'returned'
  ├── hodStatus: string      // 'pending' | 'approved' | 'rejected' | 'bypassed'
  ├── wardenStatus: string   // 'pending' | 'approved' | 'rejected' | 'waiting_for_hod' | 'bypassed'
  ├── rectorStatus: string   // 'pending' | 'approved' | 'rejected' | 'waiting_for_warden'
  ├── parentContact: string
  ├── feeStatus: string
  └── createdAt: timestamp
```

### Collection: `notifications`
```
notifications/{docId}
  ├── title: string
  ├── message: string
  ├── receiverUid: string    // UID or role keyword: 'warden' | 'rector' | 'hod'
  ├── type: string           // 'leave_request' | 'complaint' | 'attendance' | 'system'
  ├── relatedRequestId: string
  ├── isRead: boolean
  └── createdAt: timestamp
```

### Collection: `complaints`
```
complaints/{docId}
  ├── uid: string
  ├── studentName: string
  ├── category: string
  ├── description: string
  ├── imageUrl: string
  ├── status: string         // 'open' | 'in_progress' | 'resolved'
  ├── hostelId: string
  └── createdAt: timestamp
```

### Collection: `config` (mess menu)
```
config/mess_menu
  ├── weekKey: string        // e.g. '2026_W14' — for auto-reset detection
  ├── Monday:
  │   ├── Breakfast: string
  │   ├── Breakfast_imageUrl: string
  │   ├── Lunch: string
  │   ├── Lunch_imageUrl: string
  │   ├── Dinner: string
  │   └── Dinner_imageUrl: string
  ├── Tuesday: { ... }
  ...
  └── Sunday: { ... }
```

### Collection: `student_imports`
```
student_imports/{email}
  ├── name: string
  ├── email: string
  ├── assignedHostel: string
  ├── room: string
  ├── branch: string
  ├── category: string
  ├── year: string
  └── importedAt: timestamp
```

### Collection: `attendance`
```
attendance/{date_hostelId}
  ├── date: string           // 'YYYY-MM-DD'
  ├── hostelId: string
  ├── takenBy: string        // Warden UID
  ├── present: [uid, uid, ...]
  ├── absent: [uid, uid, ...]
  └── createdAt: timestamp
```

---

## 9. File & Image Storage

All images are stored on **Cloudinary** CDN:

| Image Type | Folder | Naming |
|-----------|--------|--------|
| Profile Photos | `profile_images/` | `{uid}.jpg` |
| Mess Meal Photos | `mess_menu/` | `{Day}_{Meal}_{timestamp}.jpg` |

- Images are compressed before upload (max 800px or 1024px)
- CDN delivery: fast worldwide
- URLs stored in Firestore alongside relevant documents

---

## 10. Deployment Guide (New College Setup)

### Step 1: Firebase Setup
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create new project: `collegeXYZ-hostel`
3. Enable **Authentication** → Google Sign-In
4. Enable **Firestore Database** → Start in production mode
5. Enable **Cloud Messaging** (FCM)
6. Download `google-services.json` → place in `android/app/`
7. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 2: Cloudinary Setup
1. Create account at [cloudinary.com](https://cloudinary.com)
2. Create an **unsigned upload preset** named `RNGPIT` (or update in `storage_repository.dart`)
3. Update `cloudName` in `storage_repository.dart` with your Cloudinary cloud name

### Step 3: App Configuration
Update `lib/app_config.dart` with college-specific branding:
```dart
const String collegeName = "XYZ College of Engineering";
const String appName = "XYZ Hostel";
const Color primaryColor = Color(0xFF002244);
```

### Step 4: First Admin
1. Build and install the app
2. Sign in with the Rector's Google account
3. In Firebase Console → Firestore → `users/{uid}` → set `role = 'rector'` manually
4. Rector now has full access

### Step 5: Import Students
1. Login as Rector/Admin
2. Go to Admin Panel → Bulk Import
3. Upload CSV with student data
4. Students can now login with their Google accounts

### Step 6: Add Staff
1. Login as Rector/Admin
2. Go to Staff Management
3. Add HODs, Wardens, Guards, Mess Manager with their Google email
4. Assign roles and hostels

### Step 7: Configure Hostels
- Hostel IDs: `BH1`, `BH2`, `BH3`, `BH4`, `GH1`, `GH2` (configurable)
- Assign wardens to specific hostel IDs

---

## 11. Security & Access Rules

### Firestore Security Rules (recommended)
```javascript
// Only authenticated users can read
// Only the owner or admin can write their profile
// Only admin/rector can write leave status changes
```

> Full security rules file available on request.

### Data Privacy
- Student data stored in Google Cloud (GDPR-compliant infrastructure)
- No third-party analytics or tracking
- Parent contact stored for emergency use only
- All data can be deleted per student request

---

## 12. Pricing & Licensing

### License Tiers

| Plan | Price | Capacity | Support |
|------|-------|----------|---------|
| **Starter** | ₹20,000/year | 1 Hostel, up to 300 students | Email |
| **Standard** | ₹50,000/year | 4 Hostels, up to 800 students | Phone + Email |
| **Enterprise** | ₹1,20,000/year | Unlimited Hostels + Students | Dedicated |

### One-Time Fees
| Service | Cost |
|---------|------|
| Installation & Setup | ₹15,000 |
| Data Migration (existing records) | ₹10,000 |
| Staff Training (half-day) | ₹5,000 |
| Custom Branding (logo, colors) | ₹8,000 |

### Annual Maintenance Contract (AMC)
- 25% of license price per year
- Includes: bug fixes, security updates, feature updates

---

## Appendix: Glossary

| Term | Meaning |
|------|---------|
| HOD | Head of Department |
| Warden | Hostel in-charge |
| Rector | Head of the Institution / Director |
| Gate Pass | Digital QR code for student exit authorization |
| FCM | Firebase Cloud Messaging (push notifications) |
| RBAC | Role-Based Access Control |
| Outing | Short campus exit (a few hours) |
| Home Leave | Extended leave to go home |
| AMC | Annual Maintenance Contract |

---

*Documentation prepared for HostelV3 v1.0*
*Contact for sales inquiries: [your email here]*
