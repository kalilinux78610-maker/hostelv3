import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import 'repositories/notification_repository.dart';
import 'complaints/admin_complaints_screen.dart';
import 'notification_screen.dart';

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
  String? _wardenCategory;
  String? _wardenFeeStatus;
  String? _currentWorkingCategory;
  String? _selectedDept;
  bool _isLoading = true;

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
          debugPrint("Warden Profile Loaded: Category=${data['category']}, FeeStatus=${data['feeStatus']}");
          setState(() {
            _wardenCategory = data['category'];
            _wardenFeeStatus = data['feeStatus'];
            _currentWorkingCategory = _wardenCategory; 
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_wardenCategory == null || _wardenFeeStatus == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_box, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Please set up your profile to view requests."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => widget.onTabChange?.call(2), // Switch to profile tab
              child: const Text("Go to Profile"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Dark Blue Curved Header
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 60,
              ),
              decoration: const BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (_selectedDept != null)
                               IconButton(
                                 onPressed: () => setState(() => _selectedDept = null),
                                 icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                                 padding: EdgeInsets.zero,
                                 constraints: const BoxConstraints(),
                               ),
                            Flexible(
                              child: Text(
                                _selectedDept ?? "Warden Dashboard",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currentWorkingCategory == 'Diploma' ? "All Students" : "$_wardenFeeStatus Students",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle
                      FittedBox(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              _buildCategorySwitchButton("Degree"),
                              _buildCategorySwitchButton("Diploma"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Logout
                      GestureDetector(
                        onTap: () => FirebaseAuth.instance.signOut(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.power_settings_new, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Floating PENDING card
            Positioned(
              bottom: -35,
              left: 0,
              right: 0,
              child: Center(child: _buildPendingCard()),
            ),
          ],
        ),

        const SizedBox(height: 50),

        // Home View: Grid or List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _selectedDept == null ? _buildDepartmentGrid() : _buildRequestList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentGrid() {
    final depts = _currentWorkingCategory == 'Degree' 
        ? WardenDepartmentScreen._degreeDepartments 
        : WardenDepartmentScreen._diplomaDepartments;

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: depts.length,
      itemBuilder: (context, index) {
        final dept = depts[index];
        return _buildDepartmentCard(dept['name'], dept['icon']);
      },
    );
  }

  Widget _buildDepartmentCard(String name, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('wardenStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dCat = (data['category'] ?? '').toString().toLowerCase().trim();
          final wCat = (_currentWorkingCategory ?? '').toString().toLowerCase().trim();
          final dBranch = (data['branch'] ?? '').toString().trim();
          final dBranchKey = dBranch.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
          final feeStatusInDoc = (data['feeStatus'] ?? '').toString().toLowerCase().trim();

          // Only show active requests (not fully processed or expired)
          if ((data['status'] ?? '') != 'pending') return false;
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          if (endDate != null && endDate.isBefore(DateTime.now())) return false;

          // Category Filter
          if (dCat != wCat) return false;

          // Fee Status Filter
          if (wCat == 'degree') {
            final wStatus = (_wardenFeeStatus ?? '').toString().toLowerCase().trim();
            if (feeStatusInDoc.isNotEmpty && feeStatusInDoc != wStatus) return false;
          }

          // Branch Filter
          if (name == 'B.VOC') {
            return dBranchKey == 'bvoc';
          } else if (name == 'BBA & MBA') {
            return dBranchKey == 'bbamba' || dBranchKey == 'bba' || dBranchKey == 'mba';
          } else {
            return dBranch == name;
          }
        }).toList();

        final count = docs.length;
        return GestureDetector(
          onTap: () => setState(() => _selectedDept = name),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: _primaryColor, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('wardenStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dCat = (data['category'] ?? '').toString().toLowerCase().trim();
          final wCat = (_currentWorkingCategory ?? '').toString().toLowerCase().trim();
          final dBranch = (data['branch'] ?? '').toString().trim();
          final dBranchKey = dBranch.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
          final feeStatusInDoc = (data['feeStatus'] ?? '').toString().toLowerCase().trim();

          // Only show active requests
          if ((data['status'] ?? '') != 'pending') return false;
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          if (endDate != null && endDate.isBefore(DateTime.now())) return false;

          if (dCat != wCat) return false;

          if (wCat == 'degree') {
            final wStatus = (_wardenFeeStatus ?? '').toString().toLowerCase().trim();
            if (feeStatusInDoc.isNotEmpty && feeStatusInDoc != wStatus) return false;
          }

          if (_selectedDept == 'B.VOC') {
            return dBranchKey == 'bvoc';
          } else if (_selectedDept == 'BBA & MBA') {
            return dBranchKey == 'bbamba' || dBranchKey == 'bba' || dBranchKey == 'mba';
          } else {
            return dBranch == _selectedDept;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.done_all, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No pending requests", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildCategorySwitchButton(String label) {
    bool isSelected = _currentWorkingCategory == label;
    return GestureDetector(
      onTap: () => setState(() {
        _currentWorkingCategory = label;
        _selectedDept = null; // Reset dept view when switching category
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _primaryColor : Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data) {
    // We can reuse the existing card design or simplify it here.
    // For now, let's navigate to the detail or approve directly
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(data['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${data['branch']} | ${data['type']}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to a dedicated approve screen or dialog
          // I will use a simple dialog for now to speed up implementation
          _showApproveDialog(context, docId, data);
        },
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Request from ${data['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Branch: ${data['branch']}"),
            Text("Room: ${data['room']}"),
            const SizedBox(height: 16),
            const Text("Reason:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['reason'] ?? 'N/A', style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, docId, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("REJECT"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, docId, 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                    child: const Text("APPROVE"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String docId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'wardenStatus': status,
      };

      if (status == 'approved') {
        updateData['rectorStatus'] = 'pending';
      } else {
        updateData['status'] = 'rejected';
      }

      await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update(updateData);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildPendingCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('wardenStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dCat = (data['category'] ?? '').toString().toLowerCase().trim();
          final wCat = (_currentWorkingCategory ?? '').toString().toLowerCase().trim();
          final feeStatusInDoc = (data['feeStatus'] ?? '').toString().toLowerCase().trim();

          // Only count active, non-expired requests
          if ((data['status'] ?? '') != 'pending') return false;
          final endDate = (data['endDate'] as Timestamp?)?.toDate();
          if (endDate != null && endDate.isBefore(DateTime.now())) return false;

          if (dCat != wCat) return false;

          if (wCat == 'degree') {
            final wStatus = (_wardenFeeStatus ?? '').toString().toLowerCase().trim();
            if (feeStatusInDoc.isNotEmpty && feeStatusInDoc != wStatus) return false;
          }
          return true;
        }).toList();

        final count = docs.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.access_time,
                      size: 36,
                      color: _primaryColor,
                    ),
                  ),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "PENDING",
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Category Card Widget with Red Dot
class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.category,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF002244);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('wardenStatus', isEqualTo: 'pending')
          .where('status', isEqualTo: 'pending')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        final hasRequests = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Red dot
                if (hasRequests)
                  Positioned(
                    top: -20,
                    right: -8,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 44, color: _primaryColor),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

// ============================================================
// SCREEN 2: DEPARTMENT SELECTION
// ============================================================
class WardenDepartmentScreen extends StatelessWidget {
  final String category;

  const WardenDepartmentScreen({super.key, required this.category});

  static const Color _primaryColor = Color(0xFF002244);

  // Degree Departments
  static const List<Map<String, dynamic>> _degreeDepartments = [
    {'name': 'IT & MSC-IT', 'icon': Icons.computer},
    {'name': 'B.VOC', 'icon': Icons.auto_stories},
    {'name': 'CSE', 'icon': Icons.desktop_mac},
    {'name': 'BBA & MBA', 'icon': Icons.school},
    {'name': 'Chemical', 'icon': Icons.science},
    {'name': 'Electrical', 'icon': Icons.electrical_services},
    {'name': 'Pharmacy', 'icon': Icons.local_pharmacy},
    {'name': 'Civil Engineering', 'icon': Icons.architecture},
  ];

  // Diploma Departments
  static const List<Map<String, dynamic>> _diplomaDepartments = [
    {'name': 'Electrical Engineering', 'icon': Icons.electrical_services},
    {'name': 'Chemical Engineering', 'icon': Icons.science},
    {'name': 'Information Technology', 'icon': Icons.computer},
    {'name': 'Computer Engineering', 'icon': Icons.memory},
    {'name': 'Mechanical Engineering', 'icon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    final departments = category == 'Degree'
        ? _degreeDepartments
        : _diplomaDepartments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Dark Blue Curved Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Warden",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, 2),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationScreen(userRole: 'warden'),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Department Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final dept = departments[index];
                  return _DepartmentCard(
                    name: dept['name'],
                    icon: dept['icon'],
                    category: category,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WardenDeptRequestsScreen(
                            category: category,
                            department: dept['name'],
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      if (result is int) {
                        Navigator.pop(context, result);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
              icon: Icon(Icons.assignment),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: 0,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            if (index == 0) {
              Navigator.pop(context);
            } else {
              Navigator.pop(context, index);
            }
          },
        ),
      ),
    );
  }
}

// Department Card Widget with Red Dot
class _DepartmentCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final String category;
  final VoidCallback onTap;

  const _DepartmentCard({
    required this.name,
    required this.icon,
    required this.category,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF002244);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('wardenStatus', isEqualTo: 'pending')
          .where('status', isEqualTo: 'pending')
          .where('category', isEqualTo: category)
          .where('branch', isEqualTo: name)
          .snapshots(),
      builder: (context, snapshot) {
        final hasRequests = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Red dot notification
                if (hasRequests)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 36, color: _primaryColor),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

// ============================================================
// SCREEN 3: DEPARTMENT REQUESTS (Approve / Reject)
// ============================================================
class WardenDeptRequestsScreen extends StatelessWidget {
  final String category;
  final String department;

  const WardenDeptRequestsScreen({
    super.key,
    required this.category,
    required this.department,
  });

  static const Color _primaryColor = Color(0xFF002244);

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    Map<String, dynamic> requestData,
    String action,
  ) async {
    try {
      final updateData = <String, dynamic>{};
      if (action == 'approve') {
        updateData['wardenStatus'] = 'approved';
        updateData['rectorStatus'] = 'pending'; // Pass to Rector
      } else {
        updateData['wardenStatus'] = 'rejected';
        updateData['status'] = 'rejected';
      }

      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .update(updateData);

      // Send Notifications
      final studentUid = requestData['uid'];
      final studentName = requestData['name'] ?? 'Student';

      if (action == 'approve') {
        await NotificationRepository().sendNotification(
          title: "Warden Approved Request",
          message: "Your application is pending Rector approval.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
        await NotificationRepository().sendNotification(
          title: "Approvals Required",
          message: "Warden approved $studentName's request.",
          receiverUid: 'rector',
          type: 'leave_request',
          relatedRequestId: docId,
        );
      } else {
        await NotificationRepository().sendNotification(
          title: "Request Rejected",
          message: "Warden rejected your leave application.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approve'
                  ? "Approved & Forwarded to Rector"
                  : "Request Rejected",
            ),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$category • $department",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        "Leave Requests",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Request List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leave_requests')
                  .where('wardenStatus', isEqualTo: 'pending')
                  .where('status', isEqualTo: 'pending')
                  .where('category', isEqualTo: category)
                  .where('branch', isEqualTo: department)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.done_all, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "No pending requests",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "All caught up! 🎉",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Info Row
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    (data['name'] ?? 'S')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unknown Student',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data['email'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['type'] ?? 'Leave',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Date Info
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildDateRow(
                                    Icons.logout,
                                    "From:",
                                    startDate,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDateRow(Icons.login, "To:", endDate),
                                  if (data['room'] != null) ...[
                                    const Divider(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.room,
                                          size: 16,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Room: ${data['room']}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Reason
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.notes,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['reason'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateStatus(
                                      context,
                                      doc.id,
                                      data,
                                      'reject',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(
                                        color: Colors.red,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      "REJECT",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateStatus(
                                      context,
                                      doc.id,
                                      data,
                                      'approve',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      "APPROVE",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
              icon: Icon(Icons.assignment),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: 0,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            if (index == 0) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else {
              Navigator.pop(context, index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateRow(IconData icon, String label, DateTime date) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(width: 8),
        Text(
          "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _primaryColor,
          ),
        ),
      ],
    );
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
  String? _selectedCategory;
  String? _selectedFeeStatus;

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
                _selectedCategory = doc.data()?['category'];
                _selectedFeeStatus = doc.data()?['feeStatus'];
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
            'category': _selectedCategory,
            'feeStatus': _selectedFeeStatus,
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
                              const Divider(height: 40),
                              _buildCategorySelector(),
                              const Divider(height: 40),
                              _buildFeeStatusSelector(),
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
                                    await FirebaseAuth.instance.signOut();
                                    if (context.mounted) {
                                      Navigator.popUntil(
                                        context,
                                        (route) => route.isFirst,
                                      );
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

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.school, color: _primaryColor, size: 24),
            SizedBox(width: 16),
            Text("Student Category", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionChip("Degree", _selectedCategory, (v) => setState(() => _selectedCategory = v)),
            const SizedBox(width: 12),
            _buildSelectionChip("Diploma", _selectedCategory, (v) => setState(() => _selectedCategory = v)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payments, color: _primaryColor, size: 24),
            SizedBox(width: 16),
            Text("Fee Status", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionChip("Paid", _selectedFeeStatus, (v) => setState(() => _selectedFeeStatus = v)),
            const SizedBox(width: 12),
            _buildSelectionChip("Scholarship", _selectedFeeStatus, (v) => setState(() => _selectedFeeStatus = v)),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionChip(String label, String? current, Function(String) onSelect) {
    bool isSelected = current == label;
    bool isEditable = _isEditing;
    
    return GestureDetector(
      onTap: isEditable ? () => onSelect(label) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _primaryColor : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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
