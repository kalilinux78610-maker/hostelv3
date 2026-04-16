import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../repositories/notification_repository.dart';
import '../../../../utils/canonical_names.dart';
import '../../domain/entities/complaint.dart';
import '../providers/complaint_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kNavyMid = Color(0xFF1A2E4A);
const _kAccent = Color(0xFFD4AF37); // gold
const _kSurface = Color(0xFFF7F9FC);
const _kBorder = Color(0xFFE2E8F0);

// Category data: label + icon
const _kCategories = [
  _Category('Light Problem', Icons.lightbulb_outline),
  _Category('Fan Problem', Icons.air),
  _Category('Circuit Board Problem', Icons.electrical_services),
  _Category('Bathroom Cleaning', Icons.bathroom_outlined),
  _Category('Drinking Water', Icons.water_drop_outlined),
  _Category('Mess / Food', Icons.restaurant_menu),
  _Category('Furniture Damage', Icons.chair_outlined),
  _Category('Internet / Wi-Fi', Icons.wifi_off_rounded),
  _Category('Other / General', Icons.help_outline_rounded),
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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedCategoryIndex = 0;

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
      
      // We still need user metadata from Firestore. 
      // In a full refactor, this would be in a UserProvider.
      // For now, we'll keep the fetch here but we SHOULD move it to a usecase eventually.
      final firestore = ref.read(firestoreProvider);
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final hostelId = userData?['assignedHostel'];
      final userCategory = userData?['category'];
      final userBranch = userData?['branch'];
      final studentName = CanonicalNames.canonicalName(
        userData?['name'] ?? userData?['fullName'] ?? user.email ?? 'Unknown',
      );

      final id = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

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
        setState(() => _selectedCategoryIndex = 0);
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

  @override
  Widget build(BuildContext context) {
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
              _SectionLabel(label: 'Category', icon: Icons.grid_view_rounded),
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
              const SizedBox(height: 32),
              _SubmitButton(isLoading: isLoading, onPressed: _submitComplaint),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header card ──────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kNavyMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withAlpha(75),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kAccent.withAlpha(46),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: _kAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File a Complaint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Describe your issue and we\'ll resolve it quickly.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(178),
                    fontSize: 12,
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

// ─── Category picker (scrollable chips) ───────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _CategoryPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = _kCategories[i];
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 82,
              decoration: BoxDecoration(
                color: isSelected ? _kNavy : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _kNavy : _kBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _kNavy.withAlpha(51),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat.icon,
                    size: 24,
                    color: isSelected ? _kAccent : Colors.grey[500],
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
                      color: isSelected ? Colors.white : Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
