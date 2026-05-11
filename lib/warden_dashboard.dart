import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import 'features/complaints/presentation/screens/admin_complaints_screen.dart';
import 'repositories/notification_repository.dart';
import 'services/auth_service.dart';
import 'utils/canonical_names.dart';
import '../../app_config.dart';
class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  int _selectedIndex = 0;
  static const Color _primaryColor = Color(0xFF002244);

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      WardenHomeTab(onTabChange: _onItemTapped),
      const AdminComplaintsScreen(),
      const WardenProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 1: WARDEN HOME TAB (Main Dashboard)
// ============================================================
class WardenHomeTab extends StatefulWidget {
  final Function(int)? onTabChange;
  const WardenHomeTab({super.key, this.onTabChange});

  @override
  State<WardenHomeTab> createState() => _WardenHomeTabState();
}

class _WardenHomeTabState extends State<WardenHomeTab> {
  static const Color _primaryColor = Color(0xFF002244);
  List<String> _assignedHostels = [];
  bool _isLoading = true;
  String _selectedCategory = 'Degree';
  String _selectedHostel = 'All';
  String? _wardenCategory;

  @override
  void initState() {
    super.initState();
    _loadWardenProfile();
  }

  Future<void> _loadWardenProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            if (data['assignedHostels'] != null) {
              _assignedHostels = List<String>.from(data['assignedHostels']);
            }
            if (_assignedHostels.isEmpty && data['assignedHostel'] != null) {
              _assignedHostels.add(data['assignedHostel']);
            }
            _wardenCategory = data['assignedCategory'] ?? data['category'];
            if (_wardenCategory == 'Degree' || _wardenCategory == 'Diploma') {
              _selectedCategory = _wardenCategory!;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildToggleBtn(String title) {
    bool isSel = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSel ? _primaryColor : Colors.white,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignedHostels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_box, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("You are not assigned to any hostels."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => widget.onTabChange?.call(2),
              child: const Text("Go to Profile"),
            ),
          ],
        ),
      );
    }

    final hostelsToQuery = _selectedHostel == 'All' ? _assignedHostels : [_selectedHostel];

    // Stream of all pending requests for the warden's selected hostels
    final stream = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('hostelId', whereIn: hostelsToQuery)
        .where('wardenStatus', isEqualTo: 'pending')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int totalPending = 0;
        final docs = snapshot.data?.docs ?? [];
        Map<String, Map<String, int>> counts = {'Degree': {}, 'Diploma': {}};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = CanonicalNames.canonicalizeCategory(data['category']);
          final branch = CanonicalNames.canonicalizeBranch(data['branch'], cat);
          final groupName = _getWardenDisplayGroup(branch, cat);

          if (counts.containsKey(cat)) {
            counts[cat]![groupName] = (counts[cat]![groupName] ?? 0) + 1;
          }
        }
        
        // Calculate total pending only for the currently selected category
        counts[_selectedCategory]?.values.forEach((deptCount) {
          totalPending += deptCount;
        });

        final degreeDepts = [
          {'name': 'IT & MSC-IT', 'icon': Icons.laptop},
          {'name': 'B.VOC', 'icon': Icons.menu_book},
          {'name': 'CSE', 'icon': Icons.desktop_mac},
          {'name': 'BBA & MBA', 'icon': Icons.school},
          {'name': 'Chemical', 'icon': Icons.science},
          {'name': 'Electrical', 'icon': Icons.electrical_services},
          {'name': 'Pharmacy', 'icon': Icons.local_pharmacy},
          {'name': 'Civil Engineering', 'icon': Icons.architecture},
          {'name': 'Mechanical', 'icon': Icons.settings},
        ];

        final diplomaDepts = [
          {'name': 'Computer Engineering', 'icon': Icons.computer},
          {'name': 'Mechanical Engineering', 'icon': Icons.settings},
          {'name': 'Electrical Engineering', 'icon': Icons.electrical_services},
          {'name': 'Chemical Engineering', 'icon': Icons.science},
          {'name': 'IT', 'icon': Icons.laptop},
          {'name': 'Civil Engineering', 'icon': Icons.architecture},
        ];

        final currentDepts = _selectedCategory == 'Degree' ? degreeDepts : diplomaDepts;

        return Column(
          children: [
            // ── Header Stack ───────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 16,
                    bottom: 65, // Room for the overlapping card
                  ),
                  decoration: const BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Warden Dashboard",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (_assignedHostels.length > 1)
                              SizedBox(
                                height: 24,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    dropdownColor: _primaryColor,
                                    isDense: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                    value: _selectedHostel,
                                    items: ['All', ..._assignedHostels].map((h) {
                                      return DropdownMenuItem(
                                        value: h,
                                        child: Text(
                                          h == 'All' ? 'All Hostels' : AppConfig.getFullHostelName(h),
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedHostel = val);
                                    },
                                  ),
                                ),
                              )
                            else if (_assignedHostels.isNotEmpty)
                              Text(
                                AppConfig.getFullHostelName(_assignedHostels.first),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    // Toggle
                    if (_wardenCategory == null || _wardenCategory == 'Both')
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleBtn('Degree'),
                            _buildToggleBtn('Diploma'),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _wardenCategory!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Power Button
                      GestureDetector(
                        onTap: () async {
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
                                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6)),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.redAccent.withValues(alpha: 0.15),
                                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                                      ),
                                      child: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 26),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Logging Out?',
                                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                                    const SizedBox(height: 8),
                                    Text('Are you sure you want to\nlog out of your account?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5)),
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
                                              child: const Text('Cancel', textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                                                gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text('Log Out', textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                          if (shouldLogout == true) await AuthService.signOut();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.power_settings_new, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Floating PENDING Card ──────────────────────────────
                Positioned(
                  bottom: -45, // overlaps by 45px
                  child: Container(
                    width: 130,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.access_time_filled, color: _primaryColor, size: 32),
                            if (totalPending > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$totalPending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "PENDING",
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // ── Grid of Departments ──────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                itemCount: currentDepts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final dept = currentDepts[index];
                  final String name = dept['name'] as String;
                  final IconData icon = dept['icon'] as IconData;
                  final int pendingCount = counts[_selectedCategory]?[name] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WardenDepartmentRequestsScreen(
                            branch: name,
                            category: _selectedCategory,
                            assignedHostels: hostelsToQuery,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: _primaryColor, size: 30),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Red Dot Badge
                          if (pendingCount > 0)
                            const Positioned(
                              top: 14,
                              right: 14,
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

String _getWardenDisplayGroup(String canonicalBranch, String category) {
  if (category == 'Degree') {
    if (canonicalBranch == 'Information Technology' || canonicalBranch == 'M.Sc. IT') return 'IT & MSC-IT';
    if (canonicalBranch.startsWith('B.Voc')) return 'B.VOC';
    if (canonicalBranch == 'Computer Science & Engineering') return 'CSE';
    if (canonicalBranch == 'BBA' || canonicalBranch == 'MBA') return 'BBA & MBA';
    if (canonicalBranch == 'Chemical Engineering') return 'Chemical';
    if (canonicalBranch == 'Electrical Engineering') return 'Electrical';
    if (canonicalBranch == 'Pharmacy') return 'Pharmacy';
    if (canonicalBranch == 'Civil Engineering') return 'Civil Engineering';
    if (canonicalBranch == 'Mechanical Engineering') return 'Mechanical';
  } else {
    // Diploma
    if (canonicalBranch == 'Computer Engineering') return 'Computer Engineering';
    if (canonicalBranch == 'Mechanical Engineering') return 'Mechanical Engineering';
    if (canonicalBranch == 'Electrical Engineering') return 'Electrical Engineering';
    if (canonicalBranch == 'Chemical Engineering') return 'Chemical Engineering';
    if (canonicalBranch == 'Information Technology') return 'IT';
    if (canonicalBranch == 'Civil Engineering') return 'Civil Engineering';
  }
  return canonicalBranch;
}

// ── Requests list for a specific Department + Category ──────────────────────
class WardenDepartmentRequestsScreen extends StatefulWidget {
  final String branch;
  final String category;
  final List<String> assignedHostels;

  const WardenDepartmentRequestsScreen({
    super.key,
    required this.branch,
    required this.category,
    required this.assignedHostels,
  });

  @override
  State<WardenDepartmentRequestsScreen> createState() =>
      _WardenDepartmentRequestsScreenState();
}

class _WardenDepartmentRequestsScreenState
    extends State<WardenDepartmentRequestsScreen> {
  static const Color _primaryColor = Color(0xFF002244);

  // Shows a dialog asking the Warden to enter a rejection reason.
  Future<String?> _askRejectionReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejection Reason'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this request. The student will see this reason.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Insufficient documents, Not eligible...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkUpdateStatus(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String status,
  ) async {
    final count = docs.length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pending requests to process.")),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
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
                  color: (status == 'approved' ? Colors.green : Colors.redAccent)
                      .withValues(alpha: 0.15),
                  border: Border.all(
                    color:
                        (status == 'approved' ? Colors.green : Colors.redAccent)
                            .withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  status == 'approved' ? Icons.done_all : Icons.block,
                  color:
                      status == 'approved' ? Colors.greenAccent : Colors.redAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                status == 'approved' ? 'Accept All?' : 'Reject All?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                status == 'approved'
                    ? 'Approve all $count request(s) and forward to Rector?'
                    : 'Reject all $count request(s)? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (status != 'approved') ...[
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Rejection Reason (Optional)",
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      hintText: "Reason for all rejections...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
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
                          gradient: LinearGradient(
                            colors: status == 'approved'
                                ? [
                                    const Color(0xFF11998e),
                                    const Color(0xFF38ef7d)
                                  ]
                                : [
                                    const Color(0xFFFF416C),
                                    const Color(0xFFFF4B2B)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status == 'approved' ? 'Accept All' : 'Reject All',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
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

    if (confirmed != true || !context.mounted) return;

    // Ask reason before bulk reject
    String? bulkRejectionReason;
    if (status == 'rejected') {
      bulkRejectionReason = await _askRejectionReason(context);
      if (bulkRejectionReason == null) return; // cancelled
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(status == 'approved'
          ? 'Approving $count requests...'
          : 'Rejecting $count requests...'),
      duration: const Duration(seconds: 2),
    ));

    final String reason = reasonController.text.trim();
    int successCount = 0;
    for (final doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final Map<String, dynamic> updateData = {'wardenStatus': status};
        if (status == 'approved') {
          updateData['rectorStatus'] = 'pending';
        } else {
          updateData['status'] = 'rejected';
          updateData['rejectionReason'] = (bulkRejectionReason != null && bulkRejectionReason.isNotEmpty)
              ? bulkRejectionReason
              : 'No reason provided';
          updateData['rejectedBy'] = 'Warden';
        }
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(doc.id)
            .update(updateData);

        final studentUid = data['uid'] as String?;
        final studentName = data['name'] ?? 'Student';
        if (studentUid != null) {
          if (status == 'approved') {
            await NotificationRepository().sendNotification(
              title: "Warden Approved ✅",
              message:
                  "Your leave request was approved by the Warden and is now pending Rector approval.",
              receiverUid: studentUid,
              type: 'leave_request',
              relatedRequestId: doc.id,
            );
            await NotificationRepository().sendNotification(
              title: "New Approval Required",
              message:
                  "Warden approved $studentName's leave request. Please review.",
              receiverUid: 'rector',
              type: 'leave_request',
              relatedRequestId: doc.id,
            );
          } else {
            final reason = (bulkRejectionReason != null && bulkRejectionReason.isNotEmpty)
                ? bulkRejectionReason
                : 'No reason provided';
            await NotificationRepository().sendNotification(
              title: "Request Rejected by Warden ❌",
              message: "Your leave request was rejected by the Warden. Reason: $reason",
              receiverUid: studentUid,
              type: 'leave_request',
              relatedRequestId: doc.id,
            );
          }
        }
        successCount++;
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'approved'
            ? '$successCount request(s) approved & forwarded to Rector'
            : '$successCount request(s) rejected'),
        backgroundColor: status == 'approved' ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('hostelId', whereIn: widget.assignedHostels)
        .where('wardenStatus', isEqualTo: 'pending')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.branch, style: const TextStyle(fontSize: 16)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];

          // Filter matching branch & category properly using CanonicalNames
          var filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docCat = CanonicalNames.canonicalizeCategory(data['category']);
            final docBranch =
                CanonicalNames.canonicalizeBranch(data['branch'], docCat);
            final docGroup = _getWardenDisplayGroup(docBranch, docCat);
            return docCat == widget.category && docGroup == widget.branch;
          }).toList();

          // Sort in memory to avoid missing index or missing field errors
          filteredDocs.sort((a, b) {
            final tzA =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final tzB =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (tzA == null && tzB == null) return 0;
            if (tzA == null) return 1;
            if (tzB == null) return -1;
            return tzA.compareTo(tzB); // Oldest first
          });

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No pending requests",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Bulk Action Buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _bulkUpdateStatus(context, filteredDocs, 'rejected'),
                        icon: const Icon(Icons.block, size: 16),
                        label: Text(
                          'Reject All (${filteredDocs.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _bulkUpdateStatus(context, filteredDocs, 'approved'),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text(
                          'Accept All (${filteredDocs.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestCard(context, doc.id, data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: _primaryColor.withValues(alpha: 0.1),
          child: Text(
            (data['name'] ?? 'S')[0].toUpperCase(),
            style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data['branch'] ?? ''} | Room ${data['room'] ?? ''} | ${data['type'] ?? ''}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => _showApproveDialog(context, docId, data),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final TextEditingController reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Request from ${data['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Hostel: ${AppConfig.getFullHostelName(data['hostelId'])}   Room: ${data['room'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[600])),
            Text("Branch: ${data['branch'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[600])),
            Text("Type: ${data['type'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            const Text("Reason:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['reason'] ?? 'N/A', style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: "Rejection Reason (Optional)",
                hintText: "Enter reason if rejecting...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, docId, data, 'rejected', reason: reasonController.text.trim()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("REJECT"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, docId, data, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("APPROVE"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String docId, Map<String, dynamic> data, String status) async {
    // If rejecting, ask for a reason first (close bottom sheet first)
    String? rejectionReason;
    if (status == 'rejected') {
      Navigator.pop(context); // close bottom sheet
      rejectionReason = await _askRejectionReason(context);
      if (rejectionReason == null) return; // cancelled
    }

    try {
      final updateData = <String, dynamic>{'wardenStatus': status};
      if (status == 'approved') {
        updateData['rectorStatus'] = 'pending';
      } else {
        updateData['status'] = 'rejected';
        updateData['rejectionReason'] = rejectionReason!.isNotEmpty
            ? rejectionReason
            : 'No reason provided';
        updateData['rejectedBy'] = 'Warden';
      }
      await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update(updateData);

      // Send notifications
      final studentUid = data['uid'] as String?;
      final studentName = data['name'] ?? 'Student';
      if (studentUid != null) {
        if (status == 'approved') {
          // Notify student: warden approved, now with rector
          await NotificationRepository().sendNotification(
            title: "Warden Approved ✅",
            message: "Your leave request was approved by the Warden and is now pending Rector approval.",
            receiverUid: studentUid,
            type: 'leave_request',
            relatedRequestId: docId,
          );
          // Notify rector
          await NotificationRepository().sendNotification(
            title: "New Approval Required",
            message: "Warden approved $studentName's leave request. Please review.",
            receiverUid: 'rector',
            type: 'leave_request',
            relatedRequestId: docId,
          );
        } else {
          // Notify student: rejected
          final reason = rejectionReason!.isNotEmpty ? rejectionReason : 'No reason provided';
          await NotificationRepository().sendNotification(
            title: "Request Rejected by Warden ❌",
            message: "Your leave request was rejected by the Warden. Reason: $reason",
            receiverUid: studentUid,
            type: 'leave_request',
            relatedRequestId: docId,
          );
        }
      }

      if (context.mounted) {
        // Only pop if approved (reject already popped above)
        if (status == 'approved') Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? "Request Approved & Forwarded to Rector" : "Request Rejected"),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }


}

// ============================================================
// WARDEN PROFILE TAB
// ============================================================
class WardenProfileTab extends StatefulWidget {
  const WardenProfileTab({super.key});

  @override
  State<WardenProfileTab> createState() => _WardenProfileTabState();
}

class _WardenProfileTabState extends State<WardenProfileTab> {
  final User? user = FirebaseAuth.instance.currentUser;
  static const Color _primaryColor = Color(0xFF002244);

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
      // Use on-device listener to instantly reflect backend updates without needing a restart
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots()
          .listen((doc) {
            if (doc.exists && mounted) {
              setState(() {
                _nameController.text = doc.data()?['name'] ?? "Warden";
                _phoneController.text = doc.data()?['phone'] ?? "";
                _profileImageUrl = doc.data()?['profileImageUrl'];
              });
            }
          });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot open gallery. Error: $e")),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    if (_imageBytes != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = ref.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask.whenComplete(() {});
        _profileImageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint("Upload failed: $e");
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'name': _nameController.text,
            'phone': _phoneController.text,
            if (_profileImageUrl != null) 'profileImageUrl': _profileImageUrl,
          });
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated")));
      }
    } catch (e) {
      debugPrint("Update failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 900;

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. FULL WIDTH BANNER
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: isWeb ? 70 : 60),
                  child: ClipPath(
                    clipper: WardenHeaderClipper(),
                    child: Container(
                      height: isWeb ? 300 : 200,
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
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: isWeb ? 70 : 60,
                          backgroundColor: _primaryColor,
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!) as ImageProvider
                              : (_profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(_profileImageUrl!)
                                    : null),
                          child:
                              (_imageBytes == null &&
                                  (_profileImageUrl == null ||
                                      _profileImageUrl!.isEmpty))
                              ? Icon(
                                  Icons.person,
                                  size: isWeb ? 80 : 70,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      if (_isEditing)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "WARDEN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Online Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "● Online",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Info Card
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              _buildInfoTile(
                                Icons.person,
                                "Full Name",
                                _nameController,
                                _isEditing,
                              ),
                              const Divider(height: 40),
                              _buildStaticTile(
                                Icons.email,
                                "Email Address",
                                user?.email ?? "warden@hostel.com",
                              ),
                              const Divider(height: 40),
                              _buildInfoTile(
                                Icons.phone,
                                "Phone Number",
                                _phoneController,
                                _isEditing,
                              ),
                              const Divider(height: 40),
                              _buildStaticTile(
                                Icons.badge,
                                "Employee ID",
                                "W-${user?.uid.substring(0, 5).toUpperCase() ?? 'XXXXX'}",
                              ),

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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (_isEditing) {
                                    _saveProfile();
                                  } else {
                                    setState(() => _isEditing = true);
                                  }
                                },
                                icon: Icon(
                                  _isEditing ? Icons.save : Icons.edit,
                                ),
                                label: Text(
                                  _isEditing ? "SAVE CHANGES" : "EDIT PROFILE",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!_isEditing) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFC62828),
                                    ),
                                    foregroundColor: const Color(0xFFC62828),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => _buildLogoutDialog(ctx),
                                    );
                                    if (shouldLogout == true) {
                                      await AuthService.signOut();
                                      if (context.mounted) {
                                        Navigator.popUntil(context, (route) => route.isFirst);
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text(
                                    "LOGOUT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.15),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Logging Out?',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            Text('Are you sure you want to\nlog out of your account?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5)),
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
                      child: const Text('Cancel', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                        gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Log Out', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildInfoTile(
    IconData icon,
    String title,
    TextEditingController controller,
    bool editable,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              editable
                  ? TextField(
                      controller: controller,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _primaryColor,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      controller.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WardenHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
