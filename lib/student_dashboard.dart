import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'apply_leave_screen.dart';
import 'gate_pass_screen.dart';
import 'complaints/student_complaints_screen.dart';
import 'student_profile_design_v2.dart';
import 'notification_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  static const Color _primaryColor = Color(0xFF002244);

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const StudentHomeTab(),
      const StudentComplaintsScreen(),
      const StudentProfileDesignV2(),
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
      backgroundColor: Colors.grey[100],
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
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

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  static const Color _primaryColor = Color(0xFF002244);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Not Authenticated"));
    }

    double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 800;
    final bool isSmallScreen = screenWidth < 400;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        // Extract Data
        final name = userData?['name'] ?? "Student";
        final room = userData?['room'] ?? "N/A";
        final hostel =
            userData?['assignedHostel'] ??
            userData?['hostel'] ??
            "N/A";
        final messStatus = userData?['messStatus'] ?? "Active";

        return SingleChildScrollView(
          child: Stack(
            children: [
              // Dark Blue Header Background with Bottom Curve
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: isWideScreen ? 800 : 500),
                    child: Column(
                      children: [
                        // App Bar / Top Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hello,",
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 16),
                                    ),
                                    Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationScreen(
                                            userRole: 'student',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Profile Image removed from header as per user instruction
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Floating Stats Card overlapping the header curve
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildInfoCard(
                              isSmallScreen, room, hostel, messStatus),
                        ),
                        const SizedBox(height: 30),

                        // Recent Requests
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _RecentRequestsList(uid: user.uid),
                        ),
                        const SizedBox(height: 40),

                        // Action Grid View
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildGrid(context, isWideScreen, screenWidth),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
      bool isSmall, String room, String hostel, String messStatus) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: 20, horizontal: isSmall ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
              title: room, label: "Room", icon: Icons.door_front_door_outlined),
          Container(height: 50, width: 1, color: Colors.grey[200]),
          _buildInfoItem(
              title: hostel, label: "Block", icon: Icons.apartment),
          Container(height: 50, width: 1, color: Colors.grey[200]),
          _buildInfoItem(
              title: messStatus,
              label: "Mess",
              icon: Icons.restaurant_menu_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      {required String title,
      required String label,
      required IconData icon}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _primaryColor, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, bool isWideScreen, double screenWidth) {
    // We removed 'Complaints' and 'Profile' from the grid because they are now bottom tabs.
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.article_outlined, 'label': 'Leave App'},
      {'icon': Icons.qr_code_scanner, 'label': 'Gate Pass'},
      {'icon': Icons.restaurant_menu, 'label': 'Mess Menu'},
      {'icon': Icons.event_outlined, 'label': 'Events'},
      {'icon': Icons.gavel_outlined, 'label': 'Rules'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 4 : (screenWidth < 360 ? 2 : 3),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0, // Fixed square aspect ratio for buttons
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return _buildMenuCard(
          context: context,
          icon: item['icon'] as IconData,
          title: item['label'] as String,
          onTap: () async {
            if (item['label'] == 'Leave App') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApplyLeaveScreen(),
                ),
              );
            } else if (item['label'] == 'Gate Pass') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GatePassScreen()),
              );
            } else {
              // Add other pages navigation here if needed
            }
          },
        );
      },
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: _primaryColor),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRequestsList extends StatefulWidget {
  final String uid;
  const _RecentRequestsList({required this.uid});

  @override
  State<_RecentRequestsList> createState() => _RecentRequestsListState();
}

class _RecentRequestsListState extends State<_RecentRequestsList> {
  // Rebuild every minute so expired requests disappear in real-time
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(minutes: 1), (i) => i);
  }

  /// Filter requests — only show ACTIVE/RELEVANT ones:
  /// - 'completed' → skip (done, no need to show)
  /// - 'approved' → only 1, only if endDate not passed
  /// - 'out' → show if endDate not passed (student currently out)
  /// - 'pending' → skip if endDate has already passed (stale old request)
  /// - 'rejected' → always show
  List<Map<String, dynamic>> _filterRequests(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> result = [];
    bool approvedAdded = false;

    // Sort newest first
    final sorted = List<QueryDocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    for (final doc in sorted) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      final endDate = (data['endDate'] as Timestamp?)?.toDate();

      // Skip fully completed requests
      if (status == 'completed') continue;

      if (status == 'approved') {
        // Skip expired approved requests
        if (endDate != null && endDate.isBefore(now)) continue;
        // Only show 1 active approved request
        if (approvedAdded) continue;
        approvedAdded = true;
        result.add(data);
      } else if (status == 'out') {
        // Student is currently out — show only if not overdue
        if (endDate != null && endDate.isBefore(now)) continue;
        result.add(data);
      } else if (status == 'rejected') {
        // Always show rejected so student knows
        result.add(data);
      } else if (status == 'pending') {
        // Skip old stale pending requests where return date has passed
        if (endDate != null && endDate.isBefore(now)) continue;
        result.add(data);
      }
      // Any other unknown status → skip
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Requests",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002244),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<int>(
          stream: _ticker,
          builder: (context, _) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leave_requests')
                  .where('uid', isEqualTo: widget.uid)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text("Error loading requests");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawDocs = snapshot.data?.docs ?? [];
                final filtered = _filterRequests(rawDocs);

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "No active requests.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((data) => _buildRequestCard(data)).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    String statusText = "Pending";
    Color statusColor = Colors.orange;

    final status = data['status'];
    final hodStatus = data['hodStatus'];
    final wardenStatus = data['wardenStatus'];
    final rectorStatus = data['rectorStatus'];

    if (status == 'rejected') {
      statusText = "Rejected";
      statusColor = Colors.red;
    } else if (status == 'completed') {
      statusText = "Completed ✓";
      statusColor = Colors.green;
    } else if (status == 'out') {
      final endDate = (data['endDate'] as Timestamp?)?.toDate();
      if (endDate != null) {
        final d = endDate;
        statusText = "Out • Return by ${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
      } else {
        statusText = "Currently Out";
      }
      statusColor = Colors.orange;
    } else if (status == 'approved') {
      final endDate = (data['endDate'] as Timestamp?)?.toDate();
      if (endDate != null) {
        final d = endDate;
        statusText =
            "Active • Return by ${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
      } else {
        statusText = "Fully Approved";
      }
      statusColor = Colors.green;
    } else if (hodStatus == 'pending') {
      statusText = "Waiting for HOD";
    } else if (wardenStatus == 'pending') {
      statusText = "Waiting for Warden";
    } else if (rectorStatus == 'pending') {
      statusText = "Waiting for Rector";
    } else {
      statusText = "In Review";
      statusColor = Colors.blueGrey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data['type'] == 'Home' ? Icons.home : Icons.directions_walk,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['type'] ?? 'Leave',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }
}
