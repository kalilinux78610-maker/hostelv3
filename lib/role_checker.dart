import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'rector_dashboard.dart';
import 'warden_dashboard.dart';
import 'student_dashboard.dart';
import 'guard_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'mess/mess_manager_dashboard.dart';

class RoleChecker extends StatelessWidget {
  final String uid;

  const RoleChecker({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(), // Use get() for more stable one-time routing
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle Firestore errors (permission-denied, etc.)
        if (snapshot.hasError) {
          debugPrint("RoleChecker Firestore Error: ${snapshot.error}");
          return _errorScreen("Firebase Error", "${snapshot.error}");
        }

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return _errorScreen("Data Error", "User data is empty");
          
          String role = data['role'] ?? 'student';

          // Dashboard Routing
          if (role == 'admin') return const AdminDashboardScreen();
          if (role == 'mess_manager') return const MessManagerDashboard();
          if (role == 'warden') return const WardenDashboard();
          if (role == 'guard') return const GuardDashboardScreen();
          if (role == 'rector') return const RectorDashboard();

          return const StudentDashboard();
        }

        // If user doc doesn't exist, we must log out to clear the stale session
        debugPrint("RoleChecker: User document not found for UID: $uid");
        return _errorScreen("User Not Found", "Your user profile does not exist in the database.");
      },
    );
  }

  Widget _errorScreen(String title, String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout & Fix Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
