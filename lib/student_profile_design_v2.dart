import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'repositories/storage_repository.dart';

class StudentProfileDesignV2 extends StatefulWidget {
  const StudentProfileDesignV2({super.key});

  @override
  State<StudentProfileDesignV2> createState() => _StudentProfileDesignV2State();
}

class _StudentProfileDesignV2State extends State<StudentProfileDesignV2> {
  static const Color _primary = Color(0xFF002244);

  // Editable controllers
  final _mobileCtrl = TextEditingController();
  final _fatherMobileCtrl = TextEditingController();
  final _motherMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _fatherMobileCtrl.dispose();
    _motherMobileCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic>? data) {
    _mobileCtrl.text = data?['mobile'] ?? data?['studentMobile'] ?? '';
    _fatherMobileCtrl.text = data?['fatherMobile'] ?? data?['parentContact'] ?? '';
    _motherMobileCtrl.text = data?['motherMobile'] ?? '';
    _addressCtrl.text = data?['address'] ?? '';
  }

  Future<void> _saveProfile(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'mobile': _mobileCtrl.text.trim(),
        'studentMobile': _mobileCtrl.text.trim(),
        'fatherMobile': _fatherMobileCtrl.text.trim(),
        'parentContact': _fatherMobileCtrl.text.trim(),
        'motherMobile': _motherMobileCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          // Populate controllers when data loads (only if not currently editing)
          if (!_isEditing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateControllers(data);
            });
          }

          // ── Extract all CSV fields ──────────────────────────
          final name = data?['name'] ?? user?.displayName ?? 'Student';
          final email = data?['email'] ?? user?.email ?? 'No Email';
          final photoUrl = data?['photoUrl'];
          final enrollmentNo = data?['enrollmentNo'] ?? 'N/A';
          final gender = data?['gender'] ?? 'N/A';
          final bloodGroup = data?['bloodGroup'] ?? 'N/A';
          final institute = data?['institute'] ?? 'N/A';
          final category = data?['category'] ?? 'N/A';
          final branch = data?['branch'] ?? 'N/A';
          final year = data?['year']?.toString() ?? 'N/A';
          final hostel = data?['assignedHostel'] ?? data?['hostel'] ?? 'N/A';
          final floor = data?['floor']?.toString() ?? 'N/A';
          final room = data?['room'] ?? 'N/A';
          final mobile = data?['mobile'] ?? data?['studentMobile'] ?? 'Not set';
          final fatherMobile = data?['fatherMobile'] ?? data?['parentContact'] ?? 'Not set';
          final motherMobile = data?['motherMobile'] ?? 'Not set';
          final address = data?['address'] ?? 'Not set';

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────
                _buildHeader(name, email, photoUrl, user?.uid),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── IDENTITY ──────────────────────────
                        _sectionLabel('🪪  Identity'),
                        _infoCard([
                          _row(Icons.person, 'Full Name', name),
                          _divider(),
                          _row(Icons.badge, 'Enrollment No.', enrollmentNo),
                          _divider(),
                          _row(Icons.wc, 'Gender', gender),
                          _divider(),
                          _row(Icons.bloodtype, 'Blood Group', bloodGroup),
                          _divider(),
                          _row(Icons.email, 'Email', email),
                        ]),

                        const SizedBox(height: 16),

                        // ── ACADEMIC ──────────────────────────
                        _sectionLabel('🎓  Academic Details'),
                        _infoCard([
                          _row(Icons.account_balance, 'Institute', institute),
                          _divider(),
                          _row(Icons.school, 'Category', category),
                          _divider(),
                          _row(Icons.menu_book, 'Department / Branch', branch),
                          _divider(),
                          _row(Icons.calendar_today, 'Year', year),
                        ]),

                        const SizedBox(height: 16),

                        // ── HOSTEL ────────────────────────────
                        _sectionLabel('🏠  Hostel Details'),
                        _infoCard([
                          _row(Icons.apartment, 'Hostel', hostel),
                          _divider(),
                          _row(Icons.layers, 'Floor', floor),
                          _divider(),
                          _row(Icons.door_front_door, 'Room No.', room),
                        ]),

                        const SizedBox(height: 16),

                        // ── CONTACT (Editable) ────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel('📞  Contact Details'),
                            if (!_isEditing)
                              TextButton.icon(
                                onPressed: () {
                                  _populateControllers(data);
                                  setState(() => _isEditing = true);
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _primary,
                                ),
                              ),
                          ],
                        ),

                        if (!_isEditing)
                          // Read-only contact view
                          _infoCard([
                            _row(Icons.phone_android, 'My Mobile', mobile),
                            _divider(),
                            _row(Icons.man, 'Father Mobile', fatherMobile),
                            _divider(),
                            _row(Icons.woman, 'Mother Mobile', motherMobile),
                            _divider(),
                            _row(Icons.home, 'Address', address),
                          ])
                        else
                          // Editable contact form
                          _editCard([
                            _editField(
                              controller: _mobileCtrl,
                              label: 'My Mobile No.',
                              icon: Icons.phone_android,
                              keyboard: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            _editField(
                              controller: _fatherMobileCtrl,
                              label: 'Father Mobile (used for leave requests)',
                              icon: Icons.man,
                              keyboard: TextInputType.phone,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Father mobile is required for leave requests';
                                }
                                if (v.length < 10) return 'Enter a valid 10-digit number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _editField(
                              controller: _motherMobileCtrl,
                              label: 'Mother Mobile',
                              icon: Icons.woman,
                              keyboard: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            _editField(
                              controller: _addressCtrl,
                              label: 'Permanent Address',
                              icon: Icons.home,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isEditing = false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : () => _saveProfile(user!.uid),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'SAVE CHANGES',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ]),

                        const SizedBox(height: 24),

                        // ── Logout ────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header with avatar ──────────────────────────────────────
  Widget _buildHeader(String name, String email, String? photoUrl, String? uid) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 106,
            child: ProfileAvatarWidget(photoUrl: photoUrl, uid: uid),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _editCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF002244).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _primary.withValues(alpha: 0.7)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100]);

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Profile Avatar with upload ───────────────────────────────
class ProfileAvatarWidget extends StatefulWidget {
  final String? photoUrl;
  final String? uid;

  const ProfileAvatarWidget({super.key, this.photoUrl, this.uid});

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    if (widget.uid == null) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;
      setState(() => _isUploading = true);
      final downloadUrl = await StorageRepository().uploadProfileImage(widget.uid!, image);
      if (downloadUrl != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .update({'photoUrl': downloadUrl});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      } else {
        throw 'Upload failed';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
              child: widget.photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF002244))
                  : null,
            ),
          ),
          if (_isUploading)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF002244),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
