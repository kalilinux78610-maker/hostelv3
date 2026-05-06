import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'repositories/notification_repository.dart';
import 'hod_profile_screen.dart';
import 'services/auth_service.dart';
import 'utils/canonical_names.dart';

class HodDashboardScreen extends StatefulWidget {
  const HodDashboardScreen({super.key});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  static const Color _primaryColor = Color(0xFF002244);
  String? _category;
  String? _branch;
  String? _photoUrl;
  String? _name;
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

          bool needsUpdate = false;
          String originalCategory = data?['category'] ?? '';
          String originalBranch = data?['branch'] ?? '';

          String currentCategory = CanonicalNames.canonicalizeCategory(originalCategory);
          String currentBranch = CanonicalNames.canonicalizeBranch(originalBranch, currentCategory);

          if (currentBranch != originalBranch ||
              currentCategory != originalCategory) {
            needsUpdate = true;
          }

          setState(() {
            _category = currentCategory;
            _branch = currentBranch;
            _photoUrl = data?['photoUrl'];
            _name = data?['name'];
          });

          if (needsUpdate) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'branch': currentBranch, 'category': currentCategory});
          }
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

  Widget _buildImageStatCard({
    required String title,
    required Color color,
    required IconData icon,
    required Query query,
    required bool Function(Map<String, dynamic>) filter,
    required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2E54), // Darker inner pill for cards
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text("...", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold));
              }
              final count = snapshot.data!.docs.where((d) => filter(d.data() as Map<String, dynamic>)).length;
              return Text(
                count.toString().padLeft(2, '0'),
                style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                actionText,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Widget _buildLeavesTab() {
    Query query = FirebaseFirestore.instance.collection('leave_requests').where('hodStatus', isEqualTo: 'pending');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs.toList() : [];
        
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docBranch = CanonicalNames.canonicalizeBranch(data['branch']?.toString() ?? '', data['category']?.toString() ?? '');
          final branchMatch = (_branch == null || _branch!.isEmpty) || (docBranch == _branch);
          return data['status'] == 'pending' && data['type'] == 'Home' && branchMatch;
        }).toList();

        docs.sort((a, b) {
          final aTime = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pending Requests", style: TextStyle(color: Color(0xFF001833), fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text("View all", style: TextStyle(color: Colors.blue[700], fontSize: 13, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right, color: Colors.blue[700], size: 16),
                    ],
                  ),
                ],
              ),
            ),
            if (docs.isEmpty)
              Expanded(
                child: Center(
                  child: Text("No pending requests", style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                child: Text(
                                  (data['name'] ?? 'S')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unknown Student',
                                          style: const TextStyle(color: Color(0xFF001833), fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "Pending",
                                            style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${data['branch'] ?? 'N/A'} • Room ${data['room'] ?? 'N/A'}",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${_formatDate(startDate)} - ${_formatDate(endDate)}",
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Reason: ${data['reason'] ?? 'N/A'}",
                                      style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateStatus(context, doc.id, data, 'reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateStatus(context, doc.id, data, 'approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001833),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildGatePassesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('leave_requests').where('status', isEqualTo: 'approved').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['type'] == 'Home' && data['category'] == _category && data['branch'] == _branch;
        }).toList() : [];

        docs.sort((a, b) {
          final aTime = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Currently Gate Passed", style: TextStyle(color: Color(0xFF001833), fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text("View all", style: TextStyle(color: Colors.blue[700], fontSize: 13, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right, color: Colors.blue[700], size: 16),
                    ],
                  ),
                ],
              ),
            ),
            if (docs.isEmpty)
              Expanded(
                child: Center(
                  child: Text("No active gate passes", style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.pink.withValues(alpha: 0.1),
                            child: Text(
                              (data['name'] ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      data['name'] ?? 'Unknown Student',
                                      style: const TextStyle(color: Color(0xFF001833), fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "Home",
                                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${data['branch'] ?? 'N/A'} • Room ${data['room'] ?? 'N/A'}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text("Home", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${_formatDate(startDate)} - ${_formatDate(endDate)}",
                                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Info Note at the bottom
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Note: Only 'Home' type requests appear here.\nOuting requests go directly to Rector.",
                      style: TextStyle(color: Color(0xFF001833), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF001833),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Menu & Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu, color: Colors.white70, size: 28),
              Stack(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white70, size: 28),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Profile Row
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HodProfileScreen()),
                  );
                  if (result == true) _loadHodProfile();
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null
                      ? const Icon(Icons.person, color: Color(0xFF001833), size: 32)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome back,",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _name != null && _name!.isNotEmpty ? _name! : 'Professor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _branch ?? '',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => _buildLogoutDialog(ctx),
                  );
                  if (shouldLogout == true) await AuthService.signOut();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildImageStatCard(
                  title: "Pending Requests",
                  color: Colors.orange,
                  icon: Icons.hourglass_empty,
                  query: FirebaseFirestore.instance.collection('leave_requests').where('hodStatus', isEqualTo: 'pending'),
                  filter: (data) => data['type'] == 'Home' && data['category'] == _category && data['branch'] == _branch,
                  actionText: "Awaiting your approval",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImageStatCard(
                  title: "Gate Passed",
                  color: Colors.greenAccent,
                  icon: Icons.directions_run,
                  query: FirebaseFirestore.instance.collection('leave_requests').where('status', isEqualTo: 'approved'),
                  filter: (data) => data['type'] == 'Home' && data['category'] == _category && data['branch'] == _branch,
                  actionText: "Currently out on pass",
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Pill TabBar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0A2E54),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: const Color(0xFF001833),
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 18),
                      SizedBox(width: 8),
                      Text("Requests"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 18),
                      SizedBox(width: 8),
                      Text("Passes"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_category == null || _category!.isEmpty || _branch == null || _branch!.isEmpty) {
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
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HodProfileScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadHodProfile();
                  }
                },
                child: const Text("Setup Profile"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => _buildLogoutDialog(ctx),
                  );
                  if (shouldLogout == true) await AuthService.signOut();
                },
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9), // Slightly lighter background
        body: Column(
          children: [
            _buildPremiumHeader(context),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [_buildLeavesTab(), _buildGatePassesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout Confirmation Dialog ──────────────────────────────
  Widget _buildLogoutDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
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
            // Clean Icon (no blur)
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
              child: const Icon(
                Icons.power_settings_new,
                color: Colors.redAccent,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            // Title
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
            // Subtitle
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
            // Buttons Row
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Logout Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF416C),
                            Color(0xFFFF4B2B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Log Out',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
