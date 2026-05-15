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
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HodHomeTab(),
      const HodListTab(title: "Approved Requests", statusType: "approved"),
      const HodListTab(title: "Gate Passes", statusType: "passes"),
      const HodProfileScreen(),
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user),
              label: 'Approved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.door_sliding_outlined),
              activeIcon: Icon(Icons.door_sliding),
              label: 'Passes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[400],
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

// ----------------------------------------------------
// THE DASHBOARD HOME TAB
// ----------------------------------------------------
class HodHomeTab extends StatefulWidget {
  const HodHomeTab({super.key});

  @override
  State<HodHomeTab> createState() => _HodHomeTabState();
}

class _HodHomeTabState extends State<HodHomeTab> {
  static const Color _primaryColor = Color(0xFF001833);
  static const Color _accentOrange = Color(0xFFF2994A);
  static const Color _accentGreen = Color(0xFF27AE60);

  String? _category;
  String? _branch;
  List<String> _branches = [];
  String? _photoUrl;
  String? _name;
  bool _isLoading = true;

  final int _internalTabIndex = 0; // 0: Requests, 1: Approved, 2: Passes
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHodProfile();
  }

  Future<void> _loadHodProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          bool needsUpdate = false;
          String originalCategory = data?['category'] ?? '';
          String originalBranch = data?['branch'] ?? '';
          final rawAssignedBranches = data?['assignedBranches'];

          String currentCategory = CanonicalNames.canonicalizeCategory(originalCategory);
          String currentBranch = CanonicalNames.canonicalizeBranch(originalBranch, currentCategory);
          final currentBranches = (rawAssignedBranches is List)
              ? rawAssignedBranches
                  .map((b) => CanonicalNames.canonicalizeBranch(b?.toString(), currentCategory))
                  .where((b) => b.isNotEmpty)
                  .toSet()
                  .toList()
              : <String>[];
          if (!currentBranches.contains(currentBranch) && currentBranch.isNotEmpty) {
            currentBranches.insert(0, currentBranch);
          }

          if (currentBranch != originalBranch || currentCategory != originalCategory) {
            needsUpdate = true;
          }

          if (mounted) {
            setState(() {
              _category = currentCategory;
              _branch = currentBranch;
              _branches = currentBranches;
              _photoUrl = data?['photoUrl'];
              _name = data?['name'];
            });
          }

          if (needsUpdate) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
                  'branch': currentBranch,
                  'category': currentCategory,
                  'branches': currentBranches,
                  'assignedBranches': currentBranches,
                });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading HOD profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _matchesAssignedBranch(String docBranch, String? docCategory) {
    // First check category matches
    if (_category != null && _category!.isNotEmpty && docCategory != _category) {
      return false;
    }
    // Then check branch
    if (_branches.isNotEmpty) {
      return _branches.contains(docBranch);
    }
    if (_branch == null || _branch!.isEmpty) return true;
    return docBranch == _branch;
  }

  // Shows a dialog asking the HOD to enter a rejection reason.
  // Returns null if cancelled, empty string if submitted without reason.
  Future<String?> _askRejectionReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejection Reason'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this request. The student will see this reason.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Insufficient documents, Not eligible...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null), // cancelled
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    Map<String, dynamic> requestData,
    String action,
  ) async {
    // If rejecting, ask for a reason first
    String? rejectionReason;
    if (action == 'reject') {
      rejectionReason = await _askRejectionReason(context);
      if (rejectionReason == null) return; // cancelled
    }

    try {
      final updateData = <String, dynamic>{};
      if (action == 'approve') {
        updateData['hodStatus'] = 'approved';
        updateData['wardenStatus'] = 'pending';
      } else {
        updateData['hodStatus'] = 'rejected';
        updateData['status'] = 'rejected';
        updateData['rejectionReason'] = rejectionReason!.isNotEmpty
            ? rejectionReason
            : 'No reason provided';
        updateData['rejectedBy'] = 'HOD';
      }

      await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update(updateData);

      final studentUid = requestData['uid'];
      final studentName = requestData['name'] ?? 'Student';

      if (action == 'approve') {
        await NotificationRepository().sendNotification(
          title: "HOD Approved Request",
          message: "Your application is now pending Warden approval.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
        await NotificationRepository().sendNotification(
          title: "Approvals Required",
          message: "HOD approved $studentName's request.",
          receiverUid: 'warden',
          type: 'leave_request',
          relatedRequestId: docId,
          targetCategory: CanonicalNames.canonicalizeCategory(requestData['category']?.toString() ?? ''),
          targetBranch: CanonicalNames.canonicalizeBranch(requestData['branch']?.toString() ?? '', CanonicalNames.canonicalizeCategory(requestData['category']?.toString() ?? '')),
          targetHostelId: requestData['hostelId']?.toString(),
        );
      } else {
        final reason = rejectionReason!.isNotEmpty ? rejectionReason : 'No reason provided';
        await NotificationRepository().sendNotification(
          title: "Request Rejected by HOD",
          message: "HOD rejected your leave application. Reason: $reason",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve' ? "Approved & Forwarded to Warden" : "Request Rejected"),
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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Future<void> _bulkUpdateStatus(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String action,
  ) async {
    final count = docs.length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pending requests to process.")),
      );
      return;
    }

    // For bulk reject, collect a shared reason
    final TextEditingController bulkReasonController = TextEditingController();

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
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
                  color: (action == 'approve' ? Colors.green : Colors.redAccent)
                      .withValues(alpha: 0.15),
                  border: Border.all(
                    color: (action == 'approve' ? Colors.green : Colors.redAccent)
                        .withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  action == 'approve' ? Icons.done_all : Icons.block,
                  color: action == 'approve' ? Colors.greenAccent : Colors.redAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                action == 'approve' ? 'Accept All?' : 'Reject All?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action == 'approve'
                    ? 'This will approve all $count pending request(s) and forward them to the Warden.'
                    : 'This will reject all $count pending request(s). This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              // Rejection reason field (only for reject action)
              if (action == 'reject') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: bulkReasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Rejection Reason (Optional)',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    hintText: 'e.g. Exam period...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
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
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: action == 'approve'
                                ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                                : [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          action == 'approve' ? 'Accept All' : 'Reject All',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Use reason from the inline text field
    final bulkRejectionReason = bulkReasonController.text.trim();

    // Show loading
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(action == 'approve'
            ? 'Approving $count requests...'
            : 'Rejecting $count requests...'),
        duration: const Duration(seconds: 2),
      ),
    );

    int successCount = 0;
    for (final doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final Map<String, dynamic> updateData = {};
        if (action == 'approve') {
          updateData['hodStatus'] = 'approved';
          updateData['wardenStatus'] = 'pending';
        } else {
          updateData['hodStatus'] = 'rejected';
          updateData['status'] = 'rejected';
          updateData['rejectionReason'] = bulkRejectionReason.isNotEmpty
              ? bulkRejectionReason
              : 'No reason provided';
          updateData['rejectedBy'] = 'HOD';
        }
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(doc.id)
            .update(updateData);

        final studentUid = data['uid'];
        final studentName = data['name'] ?? 'Student';
        if (action == 'approve') {
          await NotificationRepository().sendNotification(
            title: "HOD Approved Request",
            message: "Your application is now pending Warden approval.",
            receiverUid: studentUid,
            type: 'leave_request',
            relatedRequestId: doc.id,
          );
          await NotificationRepository().sendNotification(
            title: "Approvals Required",
            message: "HOD approved $studentName's request.",
            receiverUid: 'warden',
            type: 'leave_request',
            relatedRequestId: doc.id,
            targetCategory: CanonicalNames.canonicalizeCategory(data['category']?.toString() ?? ''),
            targetBranch: CanonicalNames.canonicalizeBranch(data['branch']?.toString() ?? '', CanonicalNames.canonicalizeCategory(data['category']?.toString() ?? '')),
            targetHostelId: data['hostelId']?.toString(),
          );
        } else {
          final reason = bulkRejectionReason.isNotEmpty ? bulkRejectionReason : 'No reason provided';
          await NotificationRepository().sendNotification(
            title: "Request Rejected by HOD",
            message: "HOD rejected your leave application. Reason: $reason",
            receiverUid: studentUid,
            type: 'leave_request',
            relatedRequestId: doc.id,
          );
        }
        successCount++;
      } catch (_) {}
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'approve'
              ? '$successCount request(s) approved & forwarded to Warden'
              : '$successCount request(s) rejected'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      return "Applied ${difference.inDays} days ago";
    } else if (difference.inDays == 1) {
      return "Applied yesterday";
    } else if (difference.inHours > 0) {
      return "Applied ${difference.inHours} hours ago";
    } else if (difference.inMinutes > 0) {
      return "Applied ${difference.inMinutes} minutes ago";
    } else {
      return "Applied just now";
    }
  }


  Widget _buildRequestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final name = data['name'] ?? 'Unknown Student';
    
    // Customize badge based on leave filter/type if needed
    // For now, mapping 'Home' to "Home Leave"
    String leaveTypeLabel = "Home Leave";
    IconData leaveIcon = Icons.home;
    Color leaveColor = Colors.blue.shade700;
    Color leaveBg = Colors.blue.shade50;
    
    // In actual system, we only have 'Home' leaves in HOD dashboard, but we can adjust visual based on internal logic.

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: leaveBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(leaveIcon, size: 12, color: leaveColor),
                          const SizedBox(width: 4),
                          Text(
                            leaveTypeLabel,
                            style: TextStyle(
                              color: leaveColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          // Dates
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                "${_formatDate(startDate)}  →  ${_formatDate(endDate)}",
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Time applied
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(createdAt),
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          if (_internalTabIndex == 0) // Only show Approve/Reject in Requests tab
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, doc.id, data, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade200),
                      backgroundColor: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 18),
                        SizedBox(width: 4),
                        Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, doc.id, data, 'approve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade300),
                      backgroundColor: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 4),
                        Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    Query query = FirebaseFirestore.instance.collection('leave_requests');

    if (_internalTabIndex == 0) {
      query = query.where('hodStatus', isEqualTo: 'pending');
    } else if (_internalTabIndex == 1) {
      query = query.where('hodStatus', isEqualTo: 'approved');
    } else {
      query = query.where('status', isEqualTo: 'approved');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docCategory = CanonicalNames.canonicalizeCategory(data['category']?.toString() ?? '');
          final docBranch = CanonicalNames.canonicalizeBranch(
            data['branch']?.toString() ?? '',
            docCategory,
          );
          
          // Only filter by category when BOTH HOD and request have a non-empty category
          // This avoids hiding requests from older records that may not have category saved
          final hodHasCategory = _category != null && _category!.isNotEmpty;
          final requestHasCategory = docCategory.isNotEmpty;
          final categoryMatch = !hodHasCategory ||
              !requestHasCategory ||
              docCategory.toLowerCase() == _category!.toLowerCase();

          final branchMatch = _matchesAssignedBranch(docBranch, docCategory);
          final nameMatch = data['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
          final isHome = data['type'] == 'Home';

          return branchMatch && categoryMatch && nameMatch && isHome;
        }).toList();

        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_turned_in, size: 48, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                const Text(
                  "All caught up! 🎉",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "No pending requests for\n$_branch.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // ── Bulk Action Buttons (only on Pending tab) ──
            if (_internalTabIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _bulkUpdateStatus(context, docs, 'reject'),
                        icon: const Icon(Icons.block, size: 16),
                        label: Text(
                          'Reject All (${docs.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _bulkUpdateStatus(context, docs, 'approve'),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text(
                          'Accept All (${docs.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildRequestCard(docs[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_category == null || _category!.isEmpty || (_branches.isEmpty && (_branch == null || _branch!.isEmpty))) {
      return Center(
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
                  MaterialPageRoute(builder: (context) => const HodProfileScreen()),
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
                await AuthService.signOut();
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Top Header Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 16,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Profile Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? const Icon(Icons.person, color: _primaryColor, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back,",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _name ?? 'Professor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _branches.isNotEmpty ? _branches.join(', ') : (_branch ?? ''),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2C59),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _accentOrange.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.hourglass_empty, color: _accentOrange, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('leave_requests')
                                      .where('hodStatus', isEqualTo: 'pending')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int count = 0;
                                    if (snapshot.hasData) {
                                      count = snapshot.data!.docs.where((d) {
                                        final data = d.data() as Map<String, dynamic>;
                                        final docCategory = CanonicalNames.canonicalizeCategory(
                                          data['category']?.toString() ?? '',
                                        );
                                        final hodHasCategory = _category != null && _category!.isNotEmpty;
                                        final requestHasCategory = docCategory.isNotEmpty;
                                        final categoryMatch = !hodHasCategory ||
                                            !requestHasCategory ||
                                            docCategory.toLowerCase() == _category!.toLowerCase();
                                        final docCat = docCategory;
                                        return data['type'] == 'Home' &&
                                            categoryMatch &&
                                            _matchesAssignedBranch(
                                              CanonicalNames.canonicalizeBranch(
                                                data['branch']?.toString() ?? '',
                                                docCat,
                                              ),
                                              docCat,
                                            );
                                      }).length;
                                    }
                                    return Text(
                                      "$count",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                                const Text(
                                  "Pending Requests",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Container(height: 2, width: 30, color: _accentOrange),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2C59),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _accentGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_run, color: _accentGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('leave_requests')
                                      .where('status', isEqualTo: 'approved')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int count = 0;
                                    if (snapshot.hasData) {
                                      count = snapshot.data!.docs.where((d) {
                                        final data = d.data() as Map<String, dynamic>;
                                        final docCategory = CanonicalNames.canonicalizeCategory(
                                          data['category']?.toString() ?? '',
                                        );
                                        final hodHasCategory = _category != null && _category!.isNotEmpty;
                                        final requestHasCategory = docCategory.isNotEmpty;
                                        final categoryMatch = !hodHasCategory ||
                                            !requestHasCategory ||
                                            docCategory.toLowerCase() == _category!.toLowerCase();
                                        final docCat = docCategory;
                                        return data['type'] == 'Home' &&
                                            categoryMatch &&
                                            _matchesAssignedBranch(
                                              CanonicalNames.canonicalizeBranch(
                                                data['branch']?.toString() ?? '',
                                                docCat,
                                              ),
                                              docCat,
                                            );
                                      }).length;
                                    }
                                    return Text(
                                      "$count",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                                const Text(
                                  "Gate Passes",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Container(height: 2, width: 30, color: _accentGreen),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: Column(
            children: [
              // Search & Filters Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                            hintText: "Search student...",
                            hintStyle: TextStyle(fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text("Filters", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[700]),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: _buildListContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// THE APPROVED & PASSES TABS (BOTTOM NAVIGATION)
// ----------------------------------------------------
class HodListTab extends StatefulWidget {
  final String title;
  final String statusType; // 'approved' or 'passes'

  const HodListTab({super.key, required this.title, required this.statusType});

  @override
  State<HodListTab> createState() => _HodListTabState();
}

class _HodListTabState extends State<HodListTab> {
  String? _category;
  String? _branch;
  List<String> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (mounted) {
          final category = CanonicalNames.canonicalizeCategory(data?['category'] ?? '');
          final primaryBranch = CanonicalNames.canonicalizeBranch(
            data?['branch'] ?? '',
            category,
          );
          final rawAssignedBranches = data?['assignedBranches'];
          final assignedBranches = (rawAssignedBranches is List)
              ? rawAssignedBranches
                  .map((b) => CanonicalNames.canonicalizeBranch(b?.toString(), category))
                  .where((b) => b.isNotEmpty)
                  .toSet()
                  .toList()
              : <String>[];
          if (!assignedBranches.contains(primaryBranch) && primaryBranch.isNotEmpty) {
            assignedBranches.insert(0, primaryBranch);
          }
          setState(() {
            _category = category;
            _branch = primaryBranch;
            _branches = assignedBranches;
            _isLoading = false;
          });
        }
      }
    }
  }

  bool _matchesAssignedBranch(String docBranch, String? docCategory) {
    // First check category matches
    if (_category != null && _category!.isNotEmpty && docCategory != _category) {
      return false;
    }
    // Then check branch
    if (_branches.isNotEmpty) {
      return _branches.contains(docBranch);
    }
    if (_branch == null || _branch!.isEmpty) return true;
    return docBranch == _branch;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 1) return "Applied ${difference.inDays} days ago";
    if (difference.inDays == 1) return "Applied yesterday";
    if (difference.inHours > 0) return "Applied ${difference.inHours} hours ago";
    if (difference.inMinutes > 0) return "Applied ${difference.inMinutes} minutes ago";
    return "Applied just now";
  }

  Widget _buildCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final name = data['name'] ?? 'Unknown Student';
    String leaveTypeLabel = "Home Leave";
    IconData leaveIcon = Icons.home;
    Color leaveColor = Colors.blue.shade700;
    Color leaveBg = Colors.blue.shade50;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: leaveBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(leaveIcon, size: 12, color: leaveColor),
                          const SizedBox(width: 4),
                          Text(
                            leaveTypeLabel,
                            style: TextStyle(color: leaveColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      "APPROVED",
                      style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                "${_formatDate(startDate)}  →  ${_formatDate(endDate)}",
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(createdAt),
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
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

    Query query = FirebaseFirestore.instance.collection('leave_requests');
    if (widget.statusType == 'approved') {
      query = query.where('hodStatus', isEqualTo: 'approved');
    } else if (widget.statusType == 'passes') {
      query = query.where('status', isEqualTo: 'approved');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 20,
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
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _branches.isNotEmpty ? _branches.join(', ') : "$_branch",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docCat = CanonicalNames.canonicalizeCategory(data['category']?.toString() ?? '');
                final docBranch = CanonicalNames.canonicalizeBranch(
                  data['branch']?.toString() ?? '',
                  docCat,
                );
                return _matchesAssignedBranch(docBranch, docCat) && (data['type'] == 'Home');
              }).toList();

              docs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.statusType == 'approved' ? Icons.verified_user_outlined : Icons.door_sliding_outlined,
                        size: 64, 
                        color: Colors.grey[300]
                      ),
                      const SizedBox(height: 16),
                      Text("No items found", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildCard(docs[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

