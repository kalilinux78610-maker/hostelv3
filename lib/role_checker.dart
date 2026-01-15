import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'rector_dashboard.dart';
import 'warden_dashboard.dart';
import 'student_dashboard.dart';
import 'guard_scanner_screen.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'mess/mess_manager_dashboard.dart';

class RoleChecker extends StatelessWidget {
  final String uid;

  const RoleChecker({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'student';

          // Guard logic for routing
          if (role == 'admin') {
            return const AdminDashboardScreen();
          } else if (role == 'mess_manager') {
            return const MessManagerDashboard();
          } else if (role == 'rector') {
            return const RectorDashboard();
          } else if (role == 'warden') {
            return const WardenDashboard();
          } else if (role == 'guard') {
            return const GuardScannerScreen();
          }

          return const StudentDashboard();
        }

        return const LoginScreen(); // Fallback if user doc missing
      },
    );
  }
}
