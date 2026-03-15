import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'rector_dashboard.dart';
import 'warden_dashboard.dart';
import 'student_dashboard.dart';
import 'guard_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'mess/mess_manager_dashboard.dart';
import 'hod_dashboard.dart';

class RoleChecker extends StatefulWidget {
  final String uid;

  const RoleChecker({super.key, required this.uid});

  @override
  State<RoleChecker> createState() => _RoleCheckerState();
}

class _RoleCheckerState extends State<RoleChecker> {
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots();
  }


  /// Retry fetching user data by resetting the stream
  void _retry() {
    setState(() {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots();
    });
  }

  /// Route to the correct dashboard based on role string
  Widget _getDashboard(String role) {
    debugPrint('RoleChecker: Routing user ${widget.uid} with role "$role"');

    switch (role) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'mess_manager':
        return const MessManagerDashboard();
      case 'warden':
        return const WardenDashboard();
      case 'hod':
        return const HodDashboardScreen();
      case 'guard':
        return const GuardDashboardScreen();
      case 'rector':
        return const RectorDashboard();
      case 'student':
      default:
        return const StudentDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream, 
      builder: (context, snapshot) {
        // Still loading or no data yet
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle Firestore errors
        if (snapshot.hasError) {
          debugPrint("RoleChecker Stream Error: ${snapshot.error}");
          return _errorScreen(
            "Connection Error",
            "Could not load your profile. Please check your internet connection.",
            showRetry: true,
          );
        }

        // Data loaded successfully
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null || !data.containsKey('role')) {
             // If document exists but role is missing, it might be a new doc partially synced
             return const Scaffold(
               body: Center(child: CircularProgressIndicator()),
             );
          }

          // Normalize role: trim, lowercase
          final String role = data['role']
              .toString()
              .toLowerCase()
              .trim();

          return _getDashboard(role);
        }

        // User document doesn't exist yet
        if (snapshot.connectionState == ConnectionState.active && (!snapshot.hasData || !snapshot.data!.exists)) {
           // Wait a bit longer or show error if it's definitely not there
           debugPrint("RoleChecker: User document not found for UID: ${widget.uid}");
           return _errorScreen(
             "User Not Found",
             "Your user profile does not exist in the database. Please contact support.",
           );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _errorScreen(String title, String message, {bool showRetry = false}) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (showRetry)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002244),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    try {
                      await FirebaseFirestore.instance.clearPersistence();
                    } catch (e) {
                      debugPrint("Error clearing persistence: $e");
                    }
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
