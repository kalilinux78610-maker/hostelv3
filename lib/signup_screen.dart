import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  String? _selectedHostel;
  String? _selectedBranch;
  String? _selectedYear;
  bool _isLoading = false;

  final List<String> _hostels = [
    'Boys Hostel 1',
    'Boys Hostel 2',
    'Boys Hostel 3',
    'Boys Hostel 4',
    'Girls Hostel 1',
    'Girls Hostel 2',
  ];

  final List<String> _branches = [
    'Computer Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Chemical Engineering',
  ];

  final List<String> _years = ['1', '2', '3', '4'];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      // 1. Create Auth User
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      String role = 'student';
      String? assignedHostel = _getShortHostelCode(_selectedHostel);
      Map<String, dynamic> extraData = {};

      // 2. Smart Role Check (Check if email is in Staff collection)
      final staffQuery = await FirebaseFirestore.instance
          .collection('staff')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        // IT IS A CREW MEMBER
        final staffDoc = staffQuery.docs.first;
        final staffData = staffDoc.data();

        // Map staff role to system role
        final staffRole = (staffData['role'] ?? 'student')
            .toString()
            .toLowerCase();

        if (staffRole.contains('rector')) {
          role = 'rector';
        } else if (staffRole.contains('warden')) {
          role = 'warden';
        } else if (staffRole.contains('guard')) {
          role = 'guard';
        } else if (staffRole.contains('mess')) {
          role = 'mess_manager';
        } else {
          role = staffRole;
        }

        // Override hostel from staff assignment
        assignedHostel = staffData['assignedHostel'];

        // Link Staff Doc to User
        await staffDoc.reference.update({'uid': uid});
      } else {
        // IS A STUDENT
        // Check for Pre-Imported Data
        final importQuery = await FirebaseFirestore.instance
            .collection('student_imports')
            .doc(email)
            .get();

        if (importQuery.exists) {
          final importData = importQuery.data()!;
          assignedHostel = importData['assignedHostel']; // Use imported scope

          extraData = {
            'branch': importData['branch'] ?? _selectedBranch,
            'year': importData['year'] ?? _selectedYear,
            'hostel': importData['hostel'] ?? _selectedHostel,
            'room': importData['room'], // Auto-assign room if imported
            'name': importData['name'], // Ensure name matches official record
            'isVerified': true, // Auto-verify imported students
          };
        } else {
          extraData = {
            'branch': _selectedBranch,
            'year': _selectedYear,
            'hostel': _selectedHostel,
          };
        }
      }

      // 3. Create User Document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'assignedHostel': assignedHostel, // Critical for scoping
        'mobile': _mobileController.text.trim(),
        'parentContact': _parentPhoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        ...extraData,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful! Logging in...'),
          ),
        );
        Navigator.pop(context); // Go back to login (or AuthWrapper handles it)
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration Failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _getShortHostelCode(String? fullName) {
    if (fullName == null) return null;
    if (fullName.contains('Boys Hostel 1')) return 'BH1';
    if (fullName.contains('Boys Hostel 2')) return 'BH2';
    if (fullName.contains('Boys Hostel 3')) return 'BH3';
    if (fullName.contains('Boys Hostel 4')) return 'BH4';
    if (fullName.contains('Girls Hostel 1')) return 'GH1';
    if (fullName.contains('Girls Hostel 2')) return 'GH2';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (Matching Login Style)
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF002244),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 60, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (v) =>
                          !v!.contains('@') ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDecoration('Password', Icons.lock),
                      validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Icons.lock_clock,
                      ),
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // --- Contact Details ---
                    const Text(
                      "Contact Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        'Student Mobile No.',
                        Icons.phone_android,
                      ),
                      validator: (v) =>
                          v!.length < 10 ? 'Invalid number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _parentPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        'Parent Mobile No.',
                        Icons.family_restroom,
                      ),
                      validator: (v) =>
                          v!.length < 10 ? 'Required for Hostel' : null,
                    ),
                    const SizedBox(height: 24),

                    const Row(children: [Expanded(child: Divider())]),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Student Details (Skip if Staff)",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Select Hostel', Icons.home),
                      items: _hostels
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(h)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedHostel = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        'Select Branch',
                        Icons.school,
                      ),
                      items: _branches
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBranch = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        'Select Year',
                        Icons.calendar_today,
                      ),
                      items: _years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text("Year $y"),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedYear = v),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002244),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "REGISTER",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF002244)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
