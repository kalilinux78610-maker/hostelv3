import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class ActivityFeedTab extends StatefulWidget {
  const ActivityFeedTab({super.key});

  @override
  State<ActivityFeedTab> createState() => _ActivityFeedTabState();
}

class _ActivityFeedTabState extends State<ActivityFeedTab> {
  String _selectedFilter = 'all'; // 'all', 'approved', 'pending', 'rejected'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light grey/blue background
      body: Column(
        children: [
          // Fixed Header & Stats Card
          SizedBox(
            height: 340, // Increased to prevent overlap with feed header
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeader(context),
                Positioned(
                  top: 160, // Fixed position from top to prevent overlap with text
                  left: 16,
                  right: 16,
                  child: _buildRealtimeStatsCard(),
                ),
              ],
            ),
          ),
          _buildFilterRow(),
          const SizedBox(height: 8),
          // Scrollable Feed
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _buildFeedList(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Load More',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: Colors.blue[800]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 55, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1E3A), Color(0xFF163260)],
        ),
      ),
      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.location_city,
              size: 150,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.blue[100],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Here's what's happening today.",
                      style: TextStyle(
                        color: Colors.blue[100],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => _buildLogoutDialog(ctx),
                    );
                    if (shouldLogout == true) await AuthService.signOut();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeStatsCard() {
    return StreamBuilder<QuerySnapshot>(
      // Listening to leave_requests to count real-time stats
      stream: FirebaseFirestore.instance.collection('leave_requests').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int approved = 0;
        int pending = 0;
        int rejected = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'];
            if (status == 'approved') {
              approved++;
            } else if (status == 'pending') {
              pending++;
            } else if (status == 'rejected') {
              rejected++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildStatColumn(
                  icon: Icons.description,
                  iconBg: Colors.blue[50]!,
                  iconColor: Colors.blue[400]!,
                  count: total.toString(),
                  label: 'Total Requests',
                  filterValue: 'all',
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatColumn(
                  icon: Icons.check_circle_outline,
                  iconBg: Colors.green[50]!,
                  iconColor: Colors.green[400]!,
                  count: approved.toString(),
                  label: 'Approved',
                  filterValue: 'approved',
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatColumn(
                  icon: Icons.access_time,
                  iconBg: Colors.orange[50]!,
                  iconColor: Colors.orange[400]!,
                  count: pending.toString(),
                  label: 'Pending',
                  filterValue: 'pending',
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatColumn(
                  icon: Icons.cancel_outlined,
                  iconBg: Colors.red[50]!,
                  iconColor: Colors.red[400]!,
                  count: rejected.toString(),
                  label: 'Rejected',
                  filterValue: 'rejected',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String count,
    required String label,
    required String filterValue,
  }) {
    final isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? iconBg.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 2) : null,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isSelected ? iconColor : const Color(0xFF1E293B), // Slate 800
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? iconColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildFilterRow() {
    // Only show the header if 'all' is selected
    if (_selectedFilter != 'all') {
      return const SizedBox(height: 10);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.rss_feed, color: Colors.blue[600], size: 22),
          const SizedBox(width: 10),
          const Text(
            'Live Activity Feed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A), // Slate 900
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList() {
    Query query = FirebaseFirestore.instance.collection('leave_requests');
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: Text('No recent activity')),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildActivityCard(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    final email = data['email'] ?? 'Unknown User';
    final nameStr = email.split('@')[0];

    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    final timeStr = DateFormat('d MMM, hh:mm a').format(createdAt);
    final status = data['status'];

    // Defaults for "created a request"
    String action = "created a request";
    Color actionColor = Colors.grey[700]!;
    IconData icon = Icons.note_add_outlined;
    Color iconColor = Colors.blue[600]!;
    Color iconBg = Colors.blue[50]!;
    String statusBadge = "New";
    Color badgeColor = Colors.blue[600]!;
    Color badgeBg = Colors.blue[50]!;

    // Category badge (Leave Request / Mess Complaint / Gate Pass)
    String tag = data['type'] == 'gate_pass' ? 'Gate Pass Request' : 'Leave Request';

    if (status == 'approved') {
      action = "request was approved";
      actionColor = Colors.green[600]!;
      icon = Icons.check_circle;
      iconColor = Colors.green[600]!;
      iconBg = Colors.green[50]!;
      statusBadge = "Approved";
      badgeColor = Colors.green[700]!;
      badgeBg = Colors.green[50]!;
    } else if (status == 'rejected') {
      action = "request was rejected";
      actionColor = Colors.red[500]!;
      icon = Icons.cancel;
      iconColor = Colors.red[500]!;
      iconBg = Colors.red[50]!;
      statusBadge = "Rejected";
      badgeColor = Colors.red[600]!;
      badgeBg = Colors.red[50]!;
    } else if (data['actualOutTime'] != null && data['actualInTime'] == null) {
      action = "checked out";
      actionColor = Colors.grey[700]!;
      icon = Icons.logout;
      iconColor = Colors.teal[600]!;
      iconBg = Colors.teal[50]!;
      statusBadge = "Checked Out";
      badgeColor = Colors.teal[700]!;
      badgeBg = Colors.teal[50]!;
      tag = "Hostel Checkout";
    } else if (data['actualInTime'] != null) {
      action = "checked in";
      actionColor = Colors.grey[700]!;
      icon = Icons.login;
      iconColor = Colors.teal[600]!;
      iconBg = Colors.teal[50]!;
      statusBadge = "Checked In";
      badgeColor = Colors.teal[700]!;
      badgeBg = Colors.teal[50]!;
      tag = "Hostel Check-In";
    } else if (status == 'pending') {
      action = "request is pending";
      actionColor = Colors.orange[600]!;
      icon = Icons.access_time_filled;
      iconColor = Colors.orange[500]!;
      iconBg = Colors.orange[50]!;
      statusBadge = "Pending";
      badgeColor = Colors.orange[700]!;
      badgeBg = Colors.orange[50]!;
    }

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2), // Align text with icon center slightly
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontFamily: 'Inter', // Assuming Inter is default or widely available
                    ),
                    children: [
                      TextSpan(
                        text: nameStr,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' $action',
                        style: TextStyle(
                          color: actionColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusBadge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Same logout dialog from dashboard to keep UI consistent
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
                color: Colors.redAccent.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
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
    );
  }
}
