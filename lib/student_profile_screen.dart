import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'repositories/storage_repository.dart';
import 'app_config.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _mobileController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _roomController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          _userData = doc.data();
          _mobileController.text = _userData?['mobile'] ?? '';
          _parentPhoneController.text = _userData?['fatherMobile'] ?? _userData?['parentContact'] ?? '';
          _roomController.text = _userData?['room'] ?? '';
          _addressController.text = _userData?['address'] ?? '';
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Upload to Storage
        String? downloadUrl = await StorageRepository().uploadProfileImage(
          user.uid,
          image,
        );

        if (downloadUrl != null) {
          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'photoUrl': downloadUrl});

          // Update Local State
          await _fetchProfile();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        } else {
          throw "Upload failed";
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'mobile': _mobileController.text.trim(),
              'parentContact': _parentPhoneController.text.trim(),
              'room': _roomController.text.trim(),
              'address': _addressController.text.trim(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _userData?['photoUrl'] != null
                          ? NetworkImage(_userData!['photoUrl'])
                          : null,
                      child: _userData?['photoUrl'] == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF002244),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── IDENTITY CARD ──────────────────────────────
              _sectionHeader('Identity'),
              _buildReadOnlyField("Full Name", _userData?['name'] ?? 'N/A', Icons.person),
              _buildReadOnlyField("Enrollment No.", AppConfig.formatEnrollmentNo(_userData?['enrollmentNo']), Icons.badge),
              _buildReadOnlyField("Gender", _userData?['gender'] ?? 'N/A', Icons.wc),
              _buildReadOnlyField("Blood Group", _userData?['bloodGroup'] ?? 'N/A', Icons.bloodtype),
              _buildReadOnlyField("Email", _userData?['email'] ?? 'N/A', Icons.email),

              // ── ACADEMIC CARD ──────────────────────────────
              const SizedBox(height: 8),
              _sectionHeader('Academic Details'),
              _buildReadOnlyField("Institute", _userData?['institute'] ?? 'N/A', Icons.account_balance),
              _buildReadOnlyField("Category", _userData?['category'] ?? 'N/A', Icons.school),
              _buildReadOnlyField("Department", _userData?['branch'] ?? 'N/A', Icons.menu_book),
              _buildReadOnlyField("Year", _userData?['year']?.toString() ?? 'N/A', Icons.calendar_today),

              // ── HOSTEL CARD ──────────────────────────────
              const SizedBox(height: 8),
              _sectionHeader('Hostel Details'),
              _buildReadOnlyField("Hostel", (_userData?['assignedHostel'] ?? _userData?['hostel']) != null ? AppConfig.getFullHostelName(_userData?['assignedHostel'] ?? _userData?['hostel']) : 'N/A', Icons.home),
              _buildReadOnlyField("Floor", _userData?['floor']?.toString() ?? 'N/A', Icons.layers),
              _buildReadOnlyField("Room No.", _userData?['room'] ?? 'N/A', Icons.door_front_door),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _sectionHeader('My Details (Editable)'),

              TextFormField(
                controller: _roomController,
                decoration: _inputDecoration(
                  "Room Number",
                  Icons.door_front_door,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  "My Mobile No.",
                  Icons.phone_android,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _parentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  "Father Mobile (For Leave Requests)",
                  Icons.family_restroom,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Father contact is required for Leave Requests';
                  }
                  if (val.length < 10) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: _inputDecoration("Permanent Address", Icons.home),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE CHANGES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF002244),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF002244), size: 20) : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF002244)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
