import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'repositories/storage_repository.dart';
import 'services/auth_service.dart';
import 'app_config.dart';

class StudentProfileDesignV2 extends StatefulWidget {
  const StudentProfileDesignV2({super.key});

  @override
  State<StudentProfileDesignV2> createState() => _StudentProfileDesignV2State();
}

class _StudentProfileDesignV2State extends State<StudentProfileDesignV2> {
  static const Color _primary = Color(0xFF002244);

  // Editable controllers
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _fatherMobileCtrl = TextEditingController();
  final _motherMobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _enrollmentCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final bool _isEditing = false;
  bool _isEditingEnrollment = false;
  bool _isEditingYear = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _fatherMobileCtrl.dispose();
    _motherMobileCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic>? data) {
    _nameCtrl.text = data?['name'] ?? data?['fullName'] ?? '';
    _mobileCtrl.text = data?['mobile'] ?? data?['studentMobile'] ?? '';
    _fatherMobileCtrl.text = data?['fatherMobile'] ?? data?['parentContact'] ?? '';
    _motherMobileCtrl.text = data?['motherMobile'] ?? '';
    _addressCtrl.text = data?['address'] ?? '';
    _enrollmentCtrl.text = data?['enrollmentNo'] ?? '';
    _yearCtrl.text = data?['year']?.toString() ?? '';
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
          final enrollmentNo = AppConfig.formatEnrollmentNo(data?['enrollmentNo']);
          final gender = data?['gender'] ?? 'N/A';
          final bloodGroup = data?['bloodGroup'] ?? 'N/A';
          final institute = data?['institute'] ?? 'N/A';
          final category = data?['category'] ?? 'N/A';
          final branch = data?['branch'] ?? 'N/A';
          final year = data?['year']?.toString() ?? 'N/A';
          final rawHostel = data?['assignedHostel'] ?? data?['hostel'] ?? 'N/A';
          final hostel = rawHostel != 'N/A' ? AppConfig.getFullHostelName(rawHostel) : 'N/A';
          final floor = data?['floor']?.toString() ?? 'N/A';
          final room = data?['room'] ?? 'N/A';
          final mobile = data?['mobile'] ?? data?['studentMobile'] ?? 'Not set';
          final fatherMobile = data?['fatherMobile'] ?? data?['parentContact'] ?? 'Not set';
          final motherMobile = data?['motherMobile'] ?? 'Not set';

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
                          _isEditingEnrollment
                              ? _editableRowInput(Icons.badge, 'Enrollment No.', _enrollmentCtrl, () async {
                                  if (_enrollmentCtrl.text.trim().isNotEmpty) {
                                    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                                      'enrollmentNo': _enrollmentCtrl.text.trim(),
                                    });
                                  }
                                  setState(() => _isEditingEnrollment = false);
                                })
                              : _row(Icons.badge, 'Enrollment No.', enrollmentNo, onEdit: () {
                                  setState(() => _isEditingEnrollment = true);
                                }),
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
                          _isEditingYear
                              ? _editableRowInput(Icons.calendar_today, 'Year', _yearCtrl, () async {
                                  if (_yearCtrl.text.trim().isNotEmpty) {
                                    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                                      'year': _yearCtrl.text.trim(),
                                    });
                                  }
                                  setState(() => _isEditingYear = false);
                                })
                              : _row(Icons.calendar_today, 'Year', year, onEdit: () {
                                  setState(() => _isEditingYear = true);
                                }),
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
                        _sectionLabel('📞  Contact Details'),
                        _infoCard([
                          _row(Icons.phone_android, 'My Mobile', mobile),
                          _divider(),
                          _row(Icons.man, 'Father Mobile', fatherMobile),
                          _divider(),
                          _row(Icons.woman, 'Mother Mobile', motherMobile),
                        ]),

                        const SizedBox(height: 24),

                        // ── Logout ────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1a1a2e),
                                          Color(0xFF16213e),
                                          Color(0xFF0f3460),
                                        ],
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
                                        // Clean Icon
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.redAccent.withValues(alpha: 0.15),
                                            border: Border.all(
                                              color: Colors.redAccent.withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.logout_rounded,
                                            color: Colors.redAccent,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Logging Out?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Are you sure you want to\nlog out of your account?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.55),
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
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
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
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
                                                      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'Log Out',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              if (shouldLogout == true) {
                                await AuthService.signOut();
                              }
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

  Widget _row(IconData icon, String label, String value, {VoidCallback? onEdit}) {
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
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
              onPressed: onEdit,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _editableRowInput(IconData icon, String label, TextEditingController ctrl, VoidCallback onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: ctrl,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _primary, width: 1.5),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.check_circle, size: 28, color: Colors.green),
            onPressed: onSave,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100]);
}

// ── Profile Avatar with upload ───────────────────────────────
class ProfileAvatarWidget extends StatefulWidget {
  final String? photoUrl;
  final String? uid;
  final double radius;

  const ProfileAvatarWidget({super.key, this.photoUrl, this.uid, this.radius = 50});

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
              radius: widget.radius,
              backgroundColor: Colors.white,
              backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
              child: widget.photoUrl == null
                  ? Icon(Icons.person, size: widget.radius, color: const Color(0xFF002244))
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
              padding: EdgeInsets.all(widget.radius * 0.12),
              decoration: BoxDecoration(
                color: const Color(0xFF002244),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: widget.radius * 0.32),
            ),
          ),
        ],
      ),
    );
  }
}
