import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class GuardProfileScreen extends StatefulWidget {
  const GuardProfileScreen({super.key});

  @override
  State<GuardProfileScreen> createState() => _GuardProfileScreenState();
}

class _GuardProfileScreenState extends State<GuardProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isEditing = false;
  Uint8List? _imageBytes;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? "Guard Name";
          _phoneController.text = doc.data()?['phone'] ?? "";
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch(e) {
      debugPrint("Error logging image: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot open gallery. Error: $e")));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) {
      return;
    }
    if (_imageBytes != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child('user_profiles').child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        final snapshot = await uploadTask.whenComplete(() {});
        _profileImageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint("Upload failed: $e");
      }
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        if (_profileImageUrl != null) 'profileImageUrl': _profileImageUrl,
      });
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated")));
      }
    } catch (e) {
      debugPrint("Update failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF002244),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. FULL WIDTH BANNER (Fixed constraints here)
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: isWeb ? 70 : 60),
                  child: ClipPath(
                    clipper: HeaderClipper(),
                    child: Container(
                      height: isWeb ? 300 : 200, // Taller on web
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/building.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Floating Avatar
                Positioned(
                  bottom: 0,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)]),
                        child: CircleAvatar(
                          radius: isWeb ? 70 : 60,
                          backgroundColor: const Color(0xFF002244),
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!) as ImageProvider
                              : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null),
                          child: (_imageBytes == null && _profileImageUrl == null)
                              ? Icon(Icons.person, size: isWeb ? 80 : 70, color: Colors.white)
                              : null,
                        ),
                      ),
                      if (_isEditing)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. CONSTRAINED CONTENT BELOW
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1000 : 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF002244), borderRadius: BorderRadius.circular(20)),
                        child: const Text("SECURITY GUARD", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                      const SizedBox(height: 30),

                      // Info Card
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              _buildInfoTile(Icons.person, "Full Name", _nameController, _isEditing),
                              const Divider(height: 40),
                              _buildStaticTile(Icons.email, "Email Address", user?.email ?? "guard@rngpit.com"),
                              const Divider(height: 40),
                              _buildInfoTile(Icons.phone, "Phone Number", _phoneController, _isEditing),
                              const Divider(height: 40),
                              _buildStaticTile(Icons.badge, "Employee ID", "G-${user?.uid.substring(0, 5).toUpperCase() ?? 'YYHQN'}"),
                              const Divider(height: 40),
                              _buildStaticTile(Icons.access_time_filled, "Shift Time", "Morning (8AM - 8PM)"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002244), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: () {
                                  if (_isEditing) {
                                    _saveProfile();
                                  } else {
                                    setState(() => _isEditing = true);
                                  }
                                },
                                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                                label: Text(_isEditing ? "SAVE CHANGES" : "EDIT PROFILE", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                          if (!_isEditing) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFC62828)), foregroundColor: const Color(0xFFC62828), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    if (context.mounted) {
                                      Navigator.popUntil(context, (route) => route.isFirst);
                                    }
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, TextEditingController controller, bool editable) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF002244).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF002244), size: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              editable
                  ? TextField(controller: controller, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF002244)), decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero))
                  : Text(controller.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF002244))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF002244).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF002244), size: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF002244)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
