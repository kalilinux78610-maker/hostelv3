import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../repositories/notification_repository.dart';

class ActivityFeedTab extends StatefulWidget {
  const ActivityFeedTab({super.key});

  @override
  State<ActivityFeedTab> createState() => _ActivityFeedTabState();
}

class _ActivityFeedTabState extends State<ActivityFeedTab> {
  String _selectedFilter = 'all'; // 'all', 'approved', 'pending', 'rejected'
  int _limit = 20; // Pagination limit

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
                      onPressed: () {
                        setState(() {
                          _limit += 20;
                        });
                      },
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
          _limit = 20; // Reset pagination when changing filter
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
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
            data['id'] = doc.id; // Inject ID for admin actions
            return _buildActivityCard(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    final email = data['email'] ?? 'Unknown User';
    final nameStr = data['name'] ?? data['studentName'] ?? email.split('@')[0];

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
      final typeStr = (data['type'] ?? '').toString();
      final isHome = typeStr == 'Home';
      final isOuting = typeStr.toLowerCase().contains('outing');

      if (isHome) {
        if (data['wardenStatus'] == 'approved') {
          action = "approved by Warden (pending Rector)";
        } else if (data['hodStatus'] == 'approved') {
          action = "approved by HOD (pending Warden)";
        } else {
          action = "is pending HOD approval";
        }
      } else if (isOuting) {
        action = "is pending Rector approval";
      } else {
        if (data['hodStatus'] == 'approved') {
          action = "approved by HOD (pending Warden)";
        } else {
          action = "is pending HOD approval";
        }
      }

      actionColor = Colors.orange[600]!;
      icon = Icons.access_time_filled;
      iconColor = Colors.orange[500]!;
      iconBg = Colors.orange[50]!;
      statusBadge = "Pending";
      badgeColor = Colors.orange[700]!;
      badgeBg = Colors.orange[50]!;
    }

    return InkWell(
      onTap: () => _showActivityDetails(context, data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }

  void _showActivityDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final email = data['email'] ?? 'Unknown';
        final name = data['name'] ?? email.split('@')[0];
        final type = data['type'] ?? 'Unknown Type';
        final reason = data['reason'] ?? 'No reason provided';
        final status = data['status'] ?? 'pending';
        final rejectionReason = data['rejectionReason'] ?? '';
        final rejectedBy = data['rejectedBy'] ?? '';
        final category = data['category'] ?? 'N/A';
        final branch = data['branch'] ?? 'N/A';
        final hostel = data['hostel'] ?? data['hostelId'] ?? 'N/A';
        final room = data['room'] ?? 'N/A';
        
        DateTime? outDate;
        DateTime? inDate;
        if (data['startDate'] != null) {
          outDate = (data['startDate'] as Timestamp).toDate();
        } else if (data['outDate'] != null) {
          outDate = (data['outDate'] as Timestamp).toDate();
        }

        if (data['endDate'] != null) {
          inDate = (data['endDate'] as Timestamp).toDate();
        } else if (data['inDate'] != null) {
          inDate = (data['inDate'] as Timestamp).toDate();
        }

        final actualOut = data['actualOutTime'] as Timestamp?;
        final actualIn = data['actualInTime'] as Timestamp?;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Request Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.blueGrey, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              _buildDetailRow(Icons.person, "Student", name),
              _buildDetailRow(Icons.email, "Email", email),
              Row(
                children: [
                  Expanded(child: _buildDetailRow(Icons.school, "Category", category)),
                  Expanded(child: _buildDetailRow(Icons.account_tree, "Branch", branch)),
                ],
              ),
              _buildDetailRow(Icons.meeting_room, "Hostel & Room", "$hostel (Room: $room)"),
              const Divider(height: 16),
              _buildDetailRow(Icons.category, "Request Type", type),
              _buildDetailRow(Icons.subject, "Reason", reason),
              if (outDate != null)
                _buildDetailRow(Icons.event_busy, "Requested Out", DateFormat('d MMM, hh:mm a').format(outDate)),
              if (inDate != null)
                _buildDetailRow(Icons.event_available, "Requested In", DateFormat('d MMM, hh:mm a').format(inDate)),
              
              if (actualOut != null || actualIn != null) ...[
                const Divider(height: 16, thickness: 0.5),
                const Text("Gate Scan Info", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                if (actualOut != null)
                  _buildDetailRow(Icons.logout, "Actual Out", DateFormat('d MMM, hh:mm a').format(actualOut.toDate()), color: Colors.blue[700]),
                if (actualIn != null)
                  _buildDetailRow(Icons.login, "Actual In", DateFormat('d MMM, hh:mm a').format(actualIn.toDate()), color: Colors.green[700]),
              ],
              const Divider(height: 16),
              
              // Granular Status
              const Text("Approval Workflow", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 12),
              _buildHorizontalWorkflow(data),
              const Divider(height: 16),

              _buildDetailRow(
                Icons.info_outline,
                "Current Status",
                status.toString().toUpperCase(),
                color: status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange),
              ),
              if (status == 'rejected' && rejectionReason.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Rejected by $rejectedBy: $rejectionReason",
                          style: TextStyle(color: Colors.red[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Contact Details Section
              const SizedBox(height: 12),
              const Text("Contact Details", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(data['uid'] ?? '').get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const Text("Contact details not available.", style: TextStyle(color: Colors.grey));
                  }
                  
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final mobile = userData?['mobile'] ?? 'N/A';
                  final parentMobile = userData?['fatherMobile'] ?? userData?['motherMobile'] ?? userData?['parentContact'] ?? 'N/A';

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (mobile != 'N/A') {
                              final Uri url = Uri.parse('tel:$mobile');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch dialer for $mobile")));
                                }
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No student phone number available.")));
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  mobile != 'N/A' ? "Student" : "N/A",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (parentMobile != 'N/A') {
                              final Uri url = Uri.parse('tel:$parentMobile');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch dialer for $parentMobile")));
                                }
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No parent phone number available.")));
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal[700],
                            side: BorderSide(color: Colors.teal[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.family_restroom, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  parentMobile != 'N/A' ? "Parent" : "N/A",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 12),
              // Admin Action Section
              if (status == 'pending' || status == 'approved') ...[
                const Divider(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAdminCancelDialog(context, data['id'], data),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("CANCEL REQUEST (ADMIN)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
                const SizedBox(height: 1),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? Colors.blueGrey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalWorkflow(Map<String, dynamic> data) {
    final String type = (data['type'] ?? '').toString();
    final bool isOuting = type.toLowerCase().contains('outing');
    final bool isHome = type == 'Home';

    if (isOuting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWorkflowStep("Rector", data['rectorStatus'] ?? 'pending'),
        ],
      );
    }

    return Row(
      children: [
        _buildWorkflowStep("HOD", data['hodStatus'] ?? 'pending'),
        _buildWorkflowDivider(data['hodStatus'] ?? 'pending'),
        _buildWorkflowStep("Warden", data['wardenStatus'] ?? 'pending'),
        if (isHome) ...[
          _buildWorkflowDivider(data['wardenStatus'] ?? 'pending'),
          _buildWorkflowStep("Rector", data['rectorStatus'] ?? 'pending'),
        ],
      ],
    );
  }

  Widget _buildWorkflowStep(String role, String status) {
    Color color = Colors.orange;
    IconData icon = Icons.access_time;
    if (status == 'approved') {
      color = Colors.green;
      icon = Icons.check;
    } else if (status == 'rejected') {
      color = Colors.red;
      icon = Icons.close;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 8),
        Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
      ],
    );
  }

  Widget _buildWorkflowDivider(String prevStatus) {
    Color color = prevStatus == 'approved' ? Colors.green : Colors.grey[300]!;
    return Expanded(
      child: Container(
        height: 2,
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: 4).copyWith(bottom: 24),
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

  void _showAdminCancelDialog(BuildContext context, String? docId, Map<String, dynamic> data) async {
    if (docId == null) return;
    
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Request?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("You are about to cancel this request as an Administrator. This will override all previous approvals."),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Cancellation Reason",
                hintText: "Enter why you are cancelling...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Back")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a reason for cancellation.")));
        return;
      }
      
      _adminCancelRequest(context, docId, data, reason);
    }
  }

  Future<void> _adminCancelRequest(BuildContext context, String docId, Map<String, dynamic> data, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update({
        'status': 'cancelled',
        'rejectedBy': 'Admin',
        'rejectionReason': reason,
      });

      final studentUid = data['uid'];
      if (studentUid != null) {
        await NotificationRepository().sendNotification(
          title: "Request Cancelled by Admin ❌",
          message: "Your request was cancelled by the Administrator. Reason: $reason",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Close details sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Request cancelled successfully."),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
