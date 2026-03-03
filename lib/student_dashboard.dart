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
      {'icon': Icons.local_laundry_service_outlined, 'label': 'Laundry'},
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
