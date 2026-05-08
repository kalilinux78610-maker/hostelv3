import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'services/auth_service.dart';
import 'student_profile_design_v2.dart'; // Import ProfileAvatarWidget

class HodProfileScreen extends StatefulWidget {
  const HodProfileScreen({super.key});

  @override
  State<HodProfileScreen> createState() => _HodProfileScreenState();
}

class _HodProfileScreenState extends State<HodProfileScreen> {
  static const Color _primaryColor = Color(0xFF002244);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _category;
  String? _branch;
  String? _photoUrl;
  bool _isDepartmentLocked = false;

  // Categories and branches — sourced from AppConfig (single source of truth)
  final List<String> _categories = ['Degree', 'Diploma'];
  final List<String> _branches = List<String>.from(AppConfig.allBranches);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';

            // Check if existing data is in our predefined lists, if not, add it
            if (data['category'] != null &&
                !_categories.contains(data['category'])) {
              _categories.insert(0, data['category']);
            }
            if (data['branch'] != null && !_branches.contains(data['branch'])) {
              _branches.insert(0, data['branch']);
            }

            _category = data['category'];
            _branch = data['branch'];
            _photoUrl = data['photoUrl'];
            _isDepartmentLocked = _category != null && _category!.isNotEmpty && _branch != null && _branch!.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_category == null || _branch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both Category and Branch"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'category': _category,
              'branch': _branch,
              'isProfileComplete': true,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // Pop and return true to refresh dashboard
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildLogoutDialog(ctx),
    );
    if (shouldLogout == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Widget _buildLogoutDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.15),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'Logging Out?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to\nlog out of your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Text('Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Log Out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.normal),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          suffixIcon: Icon(Icons.edit, color: Colors.blue.shade600, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) => value!.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool isLocked = false,
  }) {
    // Ensure the current value exists in the items list to prevent assertion errors
    final safeItems = (value != null && !items.contains(value))
        ? [value, ...items]
        : items;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: safeItems
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: isLocked ? null : onChanged,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.normal),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "HOD Profile Setup",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 12, top: 0),
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ProfileAvatarWidget(
                            photoUrl: _photoUrl,
                            uid: FirebaseAuth.instance.currentUser?.uid,
                            radius: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : "HOD Profile",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Manage your profile information",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue.shade700, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                "Personal Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            _nameController,
                            "Full Name",
                            Icons.person,
                          ),
                          _buildTextField(
                            _phoneController,
                            "Phone Number",
                            Icons.phone,
                            type: TextInputType.phone,
                          ),

                          const Divider(height: 30, color: Colors.black12),

                          Row(
                            children: [
                              Icon(Icons.domain, color: Colors.blue.shade700, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                "Department Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_isDepartmentLocked)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade800),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Department details cannot be changed once set.\nPlease contact admin if you need to update them.",
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          _buildDropdown(
                            "Category (e.g. BTech)",
                            Icons.school,
                            _category,
                            _categories,
                            (val) => setState(() => _category = val),
                            isLocked: _isDepartmentLocked,
                          ),

                          _buildDropdown(
                            "Branch (e.g. Computer Science)",
                            Icons.business,
                            _branch,
                            _branches,
                            (val) => setState(() => _branch = val),
                            isLocked: _isDepartmentLocked,
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveProfile,
                              icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_outlined, color: Colors.white),
                              label: _isSaving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Save Profile",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout,
                                  color: Color(0xFFC62828)),
                              label: const Text(
                                "Logout",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC62828),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFC62828), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
