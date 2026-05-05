import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/providers/common_providers.dart';
import '../../../../repositories/notification_repository.dart';
import '../../../../utils/canonical_names.dart';
import '../../domain/entities/complaint.dart';
import '../providers/complaint_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kNavyMid = Color(0xFF1A2E4A);
const _kSurface = Color(0xFFF7F9FC);
const _kBorder = Color(0xFFE2E8F0);

// Category data: label + icon
const _kCategories = [
  _Category('Mess Food', Icons.restaurant),
  _Category('Room Facility', Icons.bed_outlined),
  _Category('Water Problem', Icons.water_drop_outlined),
  _Category('Electricity Problem', Icons.lightbulb_outline),
  _Category('Washroom Cleaning', Icons.wc),
  _Category('Wi-Fi / Internet Problem', Icons.wifi),
  _Category('Maintenance', Icons.handyman),
  _Category('Other Issue', Icons.more_horiz),
];

class _Category {
  final String label;
  final IconData icon;
  const _Category(this.label, this.icon);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class FileComplaintScreen extends ConsumerStatefulWidget {
  const FileComplaintScreen({super.key});

  @override
  ConsumerState<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends ConsumerState<FileComplaintScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedCategoryIndex = 0;
  XFile? _pickedImage;
  bool _isUploadingImage = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_pickedImage == null) return null;
    if (mounted) setState(() => _isUploadingImage = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('complaints/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (kIsWeb) {
        final bytes = await _pickedImage!.readAsBytes();
        // 30 second timeout — if Storage is slow/blocked, skip image and continue
        await ref
            .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
            .timeout(const Duration(seconds: 30));
      } else {
        await ref
            .putFile(File(_pickedImage!.path))
            .timeout(const Duration(seconds: 30));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      // Upload failed or timed out — proceed without image
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      // Show loading in the provider if possible, or handle locally if needed for immediate feedback
      // In this refactored version, we'll use the ComplaintAction provider's state
      
      final userData = await ref.read(userDataProvider.future);
      final hostelId = userData?['assignedHostel'];
      final userCategory = userData?['category'];
      final userBranch = userData?['branch'];
      final studentName = CanonicalNames.canonicalName(
        userData?['name'] ?? userData?['fullName'] ?? user.email ?? 'Unknown',
      );

      final id = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

      // Upload image if selected
      final imageUrl = await _uploadImage(user.uid);

      // If widget disposed during upload (shouldn't happen with KeepAlive, but safety check)
      if (!mounted) return;

      final complaint = ComplaintEntity(
        id: id,
        uid: user.uid,
        userEmail: user.email ?? 'Unknown',
        studentName: studentName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _kCategories[_selectedCategoryIndex].label,
        status: 'Pending',
        createdAt: DateTime.now(),
        hostelId: hostelId,
        userCategory: userCategory,
        userBranch: userBranch,
        imageUrl: imageUrl,
      );

      await ref.read(complaintActionProvider.notifier).submitComplaint(complaint);

      // Notify both rector AND warden
      await NotificationRepository().sendNotification(
        title: 'New Complaint',
        message: '$studentName (${hostelId ?? 'Unknown Hostel'}) filed a complaint: ${complaint.category}',
        receiverUid: 'rector',
        type: 'complaint',
        relatedRequestId: id,
      );
      await NotificationRepository().sendNotification(
        title: 'New Complaint',
        message: '$studentName filed a complaint: ${complaint.category}',
        receiverUid: 'warden',
        type: 'complaint',
        relatedRequestId: id,
      );

      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategoryIndex = 0;
          _pickedImage = null;
        });
        _showSuccessSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complaint Submitted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your complaint has been forwarded to the Rector & Warden. We will resolve it as soon as possible.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Required by AutomaticKeepAliveClientMixin — keeps this tab alive when switching
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // MUST call super.build for KeepAlive to work
    final complaintState = ref.watch(complaintActionProvider);
    final isLoading = complaintState.isLoading;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Select Category', icon: Icons.grid_view_rounded),
              const SizedBox(height: 10),
              _CategoryPicker(
                selected: _selectedCategoryIndex,
                onSelect: (i) => setState(() => _selectedCategoryIndex = i),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Title', icon: Icons.title_rounded),
              const SizedBox(height: 10),
              _StyledField(
                controller: _titleController,
                hint: 'Brief summary of the issue',
                maxLines: 1,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Description', icon: Icons.notes_rounded),
              const SizedBox(height: 10),
              _StyledField(
                controller: _descriptionController,
                hint: 'Describe the problem in detail...',
                maxLines: 5,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),
              _AddPhotoRow(
                pickedImage: _pickedImage,
                onTap: _pickImage,
                onRemove: () => setState(() => _pickedImage = null),
              ),
              const SizedBox(height: 24),
              _SubmitButton(isLoading: isLoading || _isUploadingImage, onPressed: _submitComplaint),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header card (light theme) ────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_outlined,
                color: Color(0xFF4A90D9), size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File a Complaint',
                  style: TextStyle(
                    color: _kNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Raise an issue related to mess food or hostel facilities. We\'ll take care of it.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kNavy),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kNavy,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Category picker (4×2 grid) ───────────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _CategoryPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _kCategories.length,
      itemBuilder: (context, i) {
        final cat = _kCategories[i];
        final isSelected = i == selected;
        const blueColor = Color(0xFF4A90D9);
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEEF4FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? blueColor : _kBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  size: 22,
                  color: isSelected ? blueColor : const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? blueColor : const Color(0xFF64748B),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Add Photo row (functional) ─────────────────────────────────────────────────────
class _AddPhotoRow extends StatelessWidget {
  final XFile? pickedImage;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _AddPhotoRow({
    required this.pickedImage,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedImage != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasImage ? const Color(0xFFEEF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage ? const Color(0xFF4A90D9) : _kBorder,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasImage
                    ? const Color(0xFFDCEAFB)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasImage ? Icons.check_circle_outline : Icons.image_outlined,
                color: hasImage
                    ? const Color(0xFF4A90D9)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage
                        ? pickedImage!.name
                        : 'Add Photo (Optional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasImage
                          ? const Color(0xFF4A90D9)
                          : _kNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasImage ? 'Tap to change photo' : 'Upload any relevant photo',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Styled text field ─────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  const _StyledField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _kNavy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: _kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

// ─── Submit button ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [_kNavy, _kNavyMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isLoading ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kNavy.withAlpha(89),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Submit Complaint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
