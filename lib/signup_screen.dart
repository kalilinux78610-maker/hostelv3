import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/canonical_names.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _verifyManually() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Error", "Please enter both Gmail and Password");
      return;
    }

    setState(() => _isLoading = true);
    User? firebaseUser;
    try {
      // 1. Create Firebase Auth User FIRST (to get permission to read imports)
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      firebaseUser = userCredential.user;
      final uid = firebaseUser!.uid;

      // 2a. Check student_imports first
      final importDoc = await FirebaseFirestore.instance
          .collection('student_imports')
          .doc(email)
          .get();

      if (importDoc.exists) {
        // ── STUDENT SIGNUP ──────────────────────────────────
        final importData = importDoc.data()!;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'name': importData['name'],
          'role': 'student',
          'enrollmentNo': importData['enrollmentNo'] ?? '',
          'gender': importData['gender'] ?? '',
          'bloodGroup': importData['bloodGroup'] ?? '',
          'mobile': importData['mobile'] ?? '',
          'fatherMobile': importData['fatherMobile'] ?? '',
          'motherMobile': importData['motherMobile'] ?? '',
          'parentContact': importData['fatherMobile'] ?? '',
          'institute': importData['institute'] ?? '',
          'assignedHostel': importData['assignedHostel'],
          'hostel': importData['hostel'],
          'floor': importData['floor'] ?? '',
          'room': importData['room'],
          'category': CanonicalNames.canonicalizeCategory(importData['category'] ?? "Degree"),
          'branch': CanonicalNames.canonicalizeBranch(importData['branch'] ?? "N/A", importData['category'] ?? "Degree"),
          'year': importData['year'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false, // Start as false until email is verified
          'authMethod': 'password',
        });
      } else {
        // 2b. Not a student — check staff collection
        final staffQuery = await FirebaseFirestore.instance
            .collection('staff')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (staffQuery.docs.isEmpty) {
          // Not a student OR staff — block signup
          await firebaseUser.delete();
          throw "Your email ($email) is not registered. Please contact the Admin.";
        }

        // ── STAFF SIGNUP ──────────────────────────────────
        final staffData = staffQuery.docs.first.data();
        final String staffRole = staffData['role']?.toString().toLowerCase() ?? 'warden';

        // Map staff role name to system role key
        String systemRole = 'warden';
        if (staffRole.contains('rector')) { systemRole = 'rector'; }
        else if (staffRole.contains('warden')) { systemRole = 'warden'; }
        else if (staffRole.contains('guard')) { systemRole = 'guard'; }
        else if (staffRole.contains('hod')) { systemRole = 'hod'; }
        else if (staffRole.contains('mess')) { systemRole = 'mess_manager'; }

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'name': staffData['name'] ?? '',
          'role': systemRole,
          'mobile': staffData['mobile'] ?? '',
          'assignedHostel': staffData['assignedHostel'],
          'assignedHostels': staffData['assignedHostels'] ?? [],
          'assignedShift': staffData['assignedShift'],
          'assignedCategory': staffData['assignedCategory'],
          'assignedBranch': staffData['assignedBranch'],
          'assignedBranches': staffData['assignedBranches'] ?? [],
          'branch': staffData['assignedBranch'],
          'branches': staffData['assignedBranches'] ?? [],
          'category': staffData['assignedCategory'],
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false, // Start as false until email is verified
          'authMethod': 'password',
        });
      }

      // Send actual Firebase Email Verification
      await firebaseUser.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created! Please verify your email before logging in."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Verification Failed", e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Email Verification"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF002244),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 80, color: Color(0xFF002244)),
              const SizedBox(height: 24),
              const Text(
                "Verify Email Address",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Students must use their pre-registered Gmail address to verify their identity and set a password.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Manual Entry Form
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "College/Personal Gmail",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "example@gmail.com",
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Create Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF002244))
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _verifyManually,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002244),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("VERIFY EMAIL", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
