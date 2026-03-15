import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> _verifyWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      final String email = userCredential.user?.email?.toLowerCase() ?? "";

      if (email.isEmpty) {
        throw "Could not retrieve email from Google.";
      }

      // Check if user already has a profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account already verified. Logging in...")),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Verify against Rector's list
      final importDoc = await FirebaseFirestore.instance
          .collection('student_imports')
          .doc(email)
          .get();

      if (importDoc.exists) {
        final data = importDoc.data()!;
        final uid = userCredential.user!.uid;

        // Create the profile
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'name': data['name'],
          'role': 'student',
          'assignedHostel': data['assignedHostel'],
          'hostel': data['hostel'],
          'room': data['room'],
          'category': CanonicalNames.canonicalizeCategory(data['category']),
          'branch': CanonicalNames.canonicalizeBranch(data['branch'], data['category']),
          'year': data['year'],
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': true,
          'authMethod': 'google',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Enrollment Verified! Profile Created."), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        // If not in list, delete the auth user to keep it clean (optional)
        // or just show error.
        await FirebaseAuth.instance.signOut();
        await googleSignIn.signOut();
        
        if (mounted) {
          _showErrorDialog(
            "Access Denied",
            "Your Gmail ($email) is not in our hostel records. Please contact your Rector to add your email first."
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyManually() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Error", "Please enter both Gmail and Password");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Verify against Rector's list
      final importDoc = await FirebaseFirestore.instance
          .collection('student_imports')
          .doc(email)
          .get();

      if (!importDoc.exists) {
        throw "Your Gmail ($email) is not in our hostel records. Please contact your Rector.";
      }

      final importData = importDoc.data()!;

      // 2. Create Firebase Auth User
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      final uid = userCredential.user!.uid;

      // 3. Create the profile
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': importData['name'],
        'role': 'student',
        'assignedHostel': importData['assignedHostel'],
        'hostel': importData['hostel'],
        'room': importData['room'],
        'category': CanonicalNames.canonicalizeCategory(importData['category']),
        'branch': CanonicalNames.canonicalizeBranch(importData['branch'], importData['category']),
        'year': importData['year'],
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': true,
        'authMethod': 'password',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created & Verified!"), backgroundColor: Colors.green),
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
        title: const Text("Enrollment Verification"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF002244),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, size: 80, color: Color(0xFF002244)),
              const SizedBox(height: 24),
              const Text(
                "Verify with Google",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Students must use their Gmail account to claim their hostel room. Your Rector must add your email to the list first.",
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
                    child: const Text("VERIFY & CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              if (!_isLoading)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _verifyWithGoogle,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle),
                    ),
                    label: const Text(
                      "CONTINUE WITH GOOGLE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
