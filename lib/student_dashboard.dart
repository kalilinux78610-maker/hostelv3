import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'apply_leave_screen.dart';
import 'gate_pass_screen.dart';
import 'complaints/student_complaints_screen.dart';
import 'student_profile_screen.dart';
import 'notification_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const dashboardColor = Color(0xFF002244); // Dark Blue

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Authenticated")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
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
          final name = userData?['name'] ?? "STUDENT";
          final email = userData?['email'] ?? user.email;
          final room = userData?['room'] ?? "N/A";
          final hostel =
              userData?['assignedHostel'] ??
              userData?['hostel'] ??
              "Unassigned";
          // If you have a messStatus field, use it. Otherwise default to 'Active'
          // or logic based on e.g. fees paid.
          final messStatus = userData?['messStatus'] ?? "Active";

          return Column(
            children: [
              // Custom Header
              Stack(
                children: [
                  ClipPath(
                    clipper: DashboardHeaderClipper(),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      color: dashboardColor,
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Avatar, Title, Bell
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(
                                  'assets/images/student_profile.png',
                                ),
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const Text(
                                "Hostel Mate",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Student Info
                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${user.uid.substring(0, 8).toUpperCase()} | $email",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHeaderStat("Room No", room),
                              _buildHeaderStat("Block", hostel),
                              _buildHeaderStat("Mess Status", messStatus),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Scrollable Body (Grid + List)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Status card removed
                      _buildGrid(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.article_outlined, 'label': 'Leave App'},
      {'icon': Icons.qr_code_scanner, 'label': 'Gate Pass'},
      {'icon': Icons.restaurant_menu, 'label': 'Mess Menu'},
      {'icon': Icons.local_laundry_service_outlined, 'label': 'Laundry'},
      {'icon': Icons.report_problem_outlined, 'label': 'Complaints'},
      {'icon': Icons.event_outlined, 'label': 'Events'},
      {'icon': Icons.gavel_outlined, 'label': 'Rules'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
      {'icon': Icons.logout, 'label': 'Log Out'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return InkWell(
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
            } else if (item['label'] == 'Complaints') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentComplaintsScreen(),
                ),
              );
            } else if (item['label'] == 'Profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentProfileScreen(),
                ),
              );
            } else if (item['label'] == 'Log Out') {
              await FirebaseAuth.instance.signOut();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 32,
                  color: const Color(0xFF002244),
                ),
                const SizedBox(height: 12),
                Text(
                  item['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002244),
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

class DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var controlPoint = Offset(
      size.width / 2,
      size.height + 20,
    ); // Shallow curve
    var endPoint = Offset(size.width, size.height - 50);
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
