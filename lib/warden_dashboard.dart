import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
class WardenHomeTab extends StatelessWidget {
  final Function(int)? onTabChange;
  const WardenHomeTab({super.key, this.onTabChange});

  static const Color _primaryColor = Color(0xFF002244);

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Warden",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Dashboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => onTabChange?.call(2),
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
                              builder: (context) => const NotificationScreen(
                                userRole: 'warden',
                              ),
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
                ],
              ),
            ),

            // Floating PENDING card
            Positioned(
              bottom: -35,
              left: 0,
              right: 0,
              child: Center(
                child: _buildPendingCard(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 50),

        // Degree & Diploma Cards
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CategoryCard(
                        title: "Degree",
                        icon: Icons.school,
                        category: 'Degree',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WardenDepartmentScreen(
                                category: 'Degree',
                              ),
                            ),
                          );
                          if (result is int && onTabChange != null) {
                            onTabChange!(result);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CategoryCard(
                        title: "Diploma",
                        icon: Icons.menu_book,
                        category: 'Diploma',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WardenDepartmentScreen(
                                category: 'Diploma',
                              ),
                            ),
                          );
                          if (result is int && onTabChange != null) {
                            onTabChange!(result);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('wardenStatus', isEqualTo: 'pending')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
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
        final hasRequests =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

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
    final departments =
        category == 'Degree' ? _degreeDepartments : _diplomaDepartments;

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
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
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
                        builder: (context) => const NotificationScreen(
                          userRole: 'warden',
                        ),
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
              color: Colors.black.withOpacity(0.08),
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
        final hasRequests =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

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
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.done_all,
                            size: 64, color: Colors.grey[300]),
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
                    final startDate =
                        (data['startDate'] as Timestamp).toDate();
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
                                  backgroundColor:
                                      _primaryColor.withValues(alpha: 0.1),
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
                                      Icons.logout, "From:", startDate),
                                  const SizedBox(height: 8),
                                  _buildDateRow(
                                      Icons.login, "To:", endDate),
                                  if (data['room'] != null) ...[
                                    const Divider(height: 16),
                                    Row(
                                      children: [
                                        Icon(Icons.room,
                                            size: 16,
                                            color: Colors.grey[500]),
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
                                Icon(Icons.notes,
                                    size: 16, color: Colors.grey[400]),
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
                                          color: Colors.red, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
          ),
        ),
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
class WardenProfileTab extends StatelessWidget {
  const WardenProfileTab({super.key});

  static const Color _primaryColor = Color(0xFF002244);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryColor, width: 3),
                ),
                child: const CircleAvatar(
                  radius: 55,
                  backgroundColor: _primaryColor,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Warden",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? "",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "LOG OUT",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
