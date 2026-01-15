import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'repositories/notification_repository.dart';
import 'complaints/admin_complaints_screen.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF002244);

  static final List<Widget> _widgetOptions = <Widget>[
    WardenHomeTab(),
    AdminComplaintsScreen(),
    WardenProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Warden Dashboard'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

class WardenHomeTab extends StatelessWidget {
  const WardenHomeTab({super.key});

  // Warden Action: Approve (Passes to Rector) or Reject (Ends request)
  // Warden Action: Approve (Passes to Rector) or Reject (Ends request)
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
        // Note: rectorStatus stays 'pending', overall status stays 'pending' until Rector approves
      } else {
        updateData['wardenStatus'] = 'rejected';
        updateData['status'] = 'rejected'; // If Warden rejects, it's over
      }

      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .update(updateData);

      // Send Notifications
      final studentUid = requestData['uid'];
      final studentName = requestData['name'] ?? 'Student';

      if (action == 'approve') {
        // Notify Student
        await NotificationRepository().sendNotification(
          title: "Warden Approved Request",
          message: "Your application is pending Rector approval.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
        // Notify Rector
        await NotificationRepository().sendNotification(
          title: "Approvals Required",
          message: "Warden approved $studentName's request.",
          receiverUid: 'rector',
          type: 'leave_request',
          relatedRequestId: docId,
        );
      } else {
        // Notify Student (Rejected)
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
    return Column(
      children: [
        const WardenStatsHeader(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "PENDING WARDEN APPROVAL",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('leave_requests')
                      .where('wardenStatus', isEqualTo: 'pending')
                      .where(
                        'status',
                        isEqualTo: 'pending',
                      ) // Only show active requests
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
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_all, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No pending requests",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final startDate = (data['startDate'] as Timestamp)
                            .toDate();
                        final endDate = (data['endDate'] as Timestamp).toDate();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue[50],
                                      child: Text(
                                        (data['email'] ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF002244),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['email'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            "Applied: ${_formatDate(data['createdAt'])}",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDateRow("From:", startDate),
                                      const SizedBox(height: 4),
                                      _buildDateRow("To:", endDate),
                                      const Divider(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Reason: ",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              data['reason'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _updateStatus(
                                        context,
                                        doc.id,
                                        data,
                                        'reject',
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text("REJECT"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _updateStatus(
                                        context,
                                        doc.id,
                                        data,
                                        'approve',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF002244,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                      child: const Text("APPROVE"),
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
        ),
      ],
    );
  }

  Widget _buildDateRow(String label, DateTime date) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Text(
          "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ],
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return "${date.day}/${date.month}";
  }
}

class WardenStatsHeader extends StatelessWidget {
  const WardenStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF002244),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              "PENDING",
              FirebaseFirestore.instance
                  .collection('leave_requests')
                  .where('wardenStatus', isEqualTo: 'pending')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              Colors.orange,
              Icons.access_time_filled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    Stream<QuerySnapshot> stream,
    Color color,
    IconData icon,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WardenProfileTab extends StatelessWidget {
  const WardenProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF002244),
            child: Icon(Icons.security, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            "Warden",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );
  }
}
