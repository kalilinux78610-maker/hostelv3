# HostelV3

## 📱 Project Overview
HostelV3 is a comprehensive and secure mobile application built with Flutter, designed to streamline hostel management operations. It facilitates seamless communication and workflow management between students, wardens, rectors, and HODs. The app digitizes the leave request process, manages student enrollment data, and provides role-specific dashboards for efficient administration.

## ✨ Features
*   **Role-Based Access Control:** Distinct interfaces and permissions for Students, Wardens, Rectors, and HODs.
*   **Leave Management Workflow:** End-to-end digital leave request system requiring hierarchical approvals (e.g., HOD approval followed by Warden notification).
*   **Real-time Notifications:** Push notifications powered by Firebase Cloud Messaging (FCM V1) to keep stakeholders informed of leave request updates and important announcements.
*   **Warden/Rector Dashboards:** Centralized hubs for administrators to view pending requests, student statuses, and manage hostel operations.
*   **Bulk Data Import:** Python-based tooling to efficiently import and synchronize student records from CSV files directly into the database.
*   **Modern UI/UX:** Clean, responsive, and intuitive design leveraging Material Design principles.

## 📸 Screenshots
*(Add screenshots of your app here)*
<div align="center">
  <img src="placeholder_screenshot_1.png" width="200" alt="Login Screen">
  <img src="placeholder_screenshot_2.png" width="200" alt="Student Dashboard">
  <img src="placeholder_screenshot_3.png" width="200" alt="Warden Dashboard">
</div>

## 🛠 Tech Stack
*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** Dart
*   **State Management:** [Riverpod](https://riverpod.dev/) (Robust and scalable state management)
*   **Backend & Services:** 
    *   **Firebase Authentication:** Secure user sign-in and session management.
    *   **Cloud Firestore:** NoSQL database for real-time data synchronization.
    *   **Firebase Cloud Storage:** For storing user-uploaded media/documents.
    *   **Firebase Cloud Messaging (FCM):** For reliable push notifications.
*   **Key Packages:** `google_fonts`, `device_preview`, `csv`, `flutter_dotenv`, `flutter_secure_storage`.

## 📱 Target Platform
*   Android
*   iOS (Cross-platform compatibility)

## 📂 Folder Structure
The project follows a structured architecture to ensure maintainability and scalability:

```text
hostelv3/
├── android/             # Android-specific configuration and build files
├── ios/                 # iOS-specific configuration and build files
├── lib/                 # Main application code (Dart)
│   ├── core/            # App-wide constants, theme, and utilities
│   ├── features/        # Feature-first modules (Auth, Dashboard, Leave, etc.)
│   │   └── feature_name/
│   │       ├── data/    # Repositories, models, and API/Firebase calls
│   │       ├── domain/  # Entities and use cases
│   │       └── presentation/ # UI screens, widgets, and Riverpod providers
│   ├── main.dart        # Entry point of the application
├── tools/               # Utility scripts (e.g., import_students.py)
├── pubspec.yaml         # Project metadata and dependencies
└── README.md            # Project documentation
```

## 🚀 Installation & Setup

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure you have the latest stable version)
*   Dart SDK (bundled with Flutter)
*   Android Studio / VS Code
*   A connected device or emulator

### Steps to Run

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/hostelv3.git
    cd hostelv3
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Variables**
    *   Create a `.env` file in the root directory and add the necessary configuration keys (if applicable to your setup).

4.  **Firebase Configuration**
    *   Ensure the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed in their respective directories (`android/app/` and `ios/Runner/`).

5.  **Run the application**
    ```bash
    flutter run
    ```


## 📜 License
This project is licensed under the [MIT License](LICENSE).
