import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'repositories/notification_repository.dart';
import 'notification_screen.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  static const Color _primaryColor = Color(0xFF002244);
  String? _category;
  String? _branch;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHodProfile();
  }

  Future<void> _loadHodProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _category = data?['category'];
            _branch = data?['branch'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading HOD profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    Map<String, dynamic> requestData,
    String action,
  ) async {
    try {
      final updateData = <String, dynamic>{};
      if (action == 'approve') {
        updateData['hodStatus'] = 'approved';
        updateData['wardenStatus'] = 'pending'; // Now it moves to Warden
      } else {
        updateData['hodStatus'] = 'rejected';
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
        // Notify Student
        await NotificationRepository().sendNotification(
          title: "HOD Approved Request",
          message: "Your application is now pending Warden approval.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
        // Notify Warden
        await NotificationRepository().sendNotification(
          title: "Approvals Required",
          message: "HOD approved $studentName's request.",
          receiverUid: 'warden',
          type: 'leave_request',
          relatedRequestId: docId,
        );
      } else {
        // Notify Student of Rejection
        await NotificationRepository().sendNotification(
          title: "Request Rejected",
          message: "HOD rejected your leave application.",
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
                  ? "Approved & Forwarded to Warden"
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

  Widget _buildDateRow(IconData icon, String label, DateTime date) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLeavesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('hodStatus', isEqualTo: 'pending')
          .where('status', isEqualTo: 'pending')
          .where('category', isEqualTo: _category)
          .where('branch', isEqualTo: _branch)
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
                  "No pending leave requests",
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
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
                          backgroundColor: _primaryColor.withValues(alpha: 0.1),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                          _buildDateRow(Icons.logout, "From:", startDate),
                          const SizedBox(height: 8),
                          _buildDateRow(Icons.login, "To:", endDate),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reason
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.grey[400]),
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
                            onPressed: () =>
                                _updateStatus(context, doc.id, data, 'reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                            onPressed: () =>
                                _updateStatus(context, doc.id, data, 'approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildGatePassesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('status', isEqualTo: 'approved')
          .where('category', isEqualTo: _category)
          .where('branch', isEqualTo: _branch)
          .orderBy('createdAt', descending: true)
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
                Icon(Icons.directions_run, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "No active gate passes",
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
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
            final endDate = (data['endDate'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.qr_code_2, color: _primaryColor),
                ),
                title: Text(
                  data['name'] ?? 'Student',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['type'] ?? 'Leave'),
                    Text(
                      "To: ${endDate.day}/${endDate.month} ${endDate.hour}:${endDate.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "APPROVED",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComplaintsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('userCategory', isEqualTo: _category)
          .where('userBranch', isEqualTo: _branch)
          .orderBy('createdAt', descending: true)
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
                Icon(
                  Icons.sentiment_satisfied_alt,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "No complaints filed",
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
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
            final status = data['status'] ?? 'Pending';
            final isResolved = status == 'Resolved';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isResolved
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  data['title'] ?? 'Complaint',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['category'] ?? 'Category',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isResolved ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_category == null || _branch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('HOD Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Category or Branch not assigned to your profile."),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
              ),
              decoration: const BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "HOD • $_category • $_branch",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                "Dashboard",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(userRole: 'hod'),
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
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => FirebaseAuth.instance.signOut(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: "Reqs"),
                      Tab(text: "Gate Passes"),
                      Tab(text: "Complaints"),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildLeavesTab(),
                  _buildGatePassesTab(),
                  _buildComplaintsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
