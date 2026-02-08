import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'repositories/notification_repository.dart';
import 'complaints/admin_complaints_screen.dart';

class RectorDashboard extends StatefulWidget {
  const RectorDashboard({super.key});

  @override
  State<RectorDashboard> createState() => _RectorDashboardState();
}

class _RectorDashboardState extends State<RectorDashboard> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF002244);
  String? _assignedHostel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHostelAssignment();
  }

  Future<void> _fetchHostelAssignment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (mounted && data != null) {
          setState(() {
            // Normalize to UpperCase to match "BH1" format
            String? rawHostel = data['assignedHostel'];
            _assignedHostel = rawHostel?.toUpperCase();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching hostel: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Widget> get _widgetOptions => <Widget>[
    HomeTab(hostelId: _assignedHostel),
    HostelStudentsTab(hostelId: _assignedHostel), // New Tab
    HistoryTab(hostelId: _assignedHostel),
    AdminComplaintsScreen(hostelId: _assignedHostel),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _assignedHostel != null
              ? 'Rector Dashboard ($_assignedHostel)'
              : 'Rector Dashboard',
        ),
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
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
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

class HomeTab extends StatefulWidget {
  final String? hostelId;
  const HomeTab({super.key, this.hostelId});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedView = 0; // 0 for Pending, 1 for Out Now

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StatsHeader(
          hostelId: widget.hostelId,
          selectedView: _selectedView,
          onViewChanged: (index) => setState(() => _selectedView = index),
        ),
        // Removed the toggle container
        Expanded(
          child: _selectedView == 0
              ? PendingRequestsList(hostelId: widget.hostelId)
              : OutStudentsListWidget(hostelId: widget.hostelId),
        ),
      ],
    );
  }
}

class StatsHeader extends StatelessWidget {
  final String? hostelId;
  final int selectedView;
  final ValueChanged<int> onViewChanged;

  const StatsHeader({
    super.key,
    this.hostelId,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    Query pendingQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('wardenStatus', isEqualTo: 'approved')
        .where('rectorStatus', isEqualTo: 'pending')
        .where('status', isEqualTo: 'pending');

    Query outQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('actualOutTime', isNull: false)
        .where('actualInTime', isNull: true);

    if (hostelId != null) {
      pendingQuery = pendingQuery.where('hostelId', isEqualTo: hostelId);
      outQuery = outQuery.where('hostelId', isEqualTo: hostelId);
    }

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
              "PENDING REQUESTS",
              pendingQuery.snapshots(),
              Colors.orange,
              Icons.access_time_filled,
              0,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              "OUT NOW",
              outQuery.snapshots(),
              Colors.blue,
              Icons.directions_walk,
              1,
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
    int index,
  ) {
    final isSelected = selectedView == index;
    return GestureDetector(
      onTap: () => onViewChanged(index),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 4),
                  Text(
                    "Error",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : Colors.white70,
                      size: 20,
                    ),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF002244)
                            : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.grey[800] : Colors.white70,
                    fontSize: 11, // Slightly smaller to fit
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PendingRequestsList extends StatelessWidget {
  final String? hostelId;
  const PendingRequestsList({super.key, this.hostelId});

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    Map<String, dynamic> requestData,
    String status,
  ) async {
    try {
      final updateData = <String, dynamic>{};
      if (status == 'approved') {
        updateData['rectorStatus'] = 'approved';
        updateData['status'] = 'approved'; // Final approval
      } else {
        updateData['rectorStatus'] = 'rejected';
        updateData['status'] = 'rejected';
      }

      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .update(updateData);

      // Send Notifications
      final studentUid = requestData['uid'];
      if (status == 'approved') {
        await NotificationRepository().sendNotification(
          title: "Leave Request Approved",
          message:
              "Rector has approved your leave request. Gate pass generated.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
      } else {
        await NotificationRepository().sendNotification(
          title: "Request Rejected",
          message: "Rector rejected your leave application.",
          receiverUid: studentUid,
          type: 'leave_request',
          relatedRequestId: docId,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request ${status.toUpperCase()} successfully"),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
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
    Query query = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('wardenStatus', isEqualTo: 'approved')
        .where('rectorStatus', isEqualTo: 'pending')
        .where('status', isEqualTo: 'pending');

    if (hostelId != null) {
      query = query.where('hostelId', isEqualTo: hostelId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('createdAt', descending: false).snapshots(),
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
                Text("All caught up!", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final startDate = (data['startDate'] as Timestamp).toDate();
            final endDate = (data['endDate'] as Timestamp).toDate();

            final now = DateTime.now();
            final difference = startDate.difference(now).inHours;
            final isUrgent = difference <= 24;

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['email'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _formatDate(data['createdAt']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUrgent) const BlinkingUrgentBadge(),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                          onPressed: () =>
                              _updateStatus(context, doc.id, data, 'rejected'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text("REJECT"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _updateStatus(context, doc.id, data, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002244),
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

class HistoryTab extends StatefulWidget {
  final String? hostelId;
  const HistoryTab({super.key, this.hostelId});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isNotEqualTo: 'pending')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (widget.hostelId != null) {
      // Note: Firestore requires compound queries to follow index rules.
      // If we add hostelId, we might need an index: hostelId ASC, status ASC, createdAt DESC
      query = query.where('hostelId', isEqualTo: widget.hostelId);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "Search by email...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                final data = doc.data() as Map<String, dynamic>;
                final email = (data['email'] ?? "").toString().toLowerCase();
                return email.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? "No history found"
                            : "No matches for '$_searchQuery'",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final status = data['status'];
                  final isApproved = status == 'approved';

                  final actualOut = data['actualOutTime'] != null
                      ? (data['actualOutTime'] as Timestamp).toDate()
                      : null;
                  final actualIn = data['actualInTime'] != null
                      ? (data['actualInTime'] as Timestamp).toDate()
                      : null;

                  String statusText = status.toString().toUpperCase();
                  if (status == 'approved') {
                    if (actualIn != null) {
                      statusText = "COMPLETED";
                    } else if (actualOut != null) {
                      statusText = "CURRENTLY OUT";
                    }
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isApproved ? Icons.check : Icons.close,
                                color: isApproved ? Colors.green : Colors.red,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              data['email'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "$statusText • ${data['type'] ?? 'Home'}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDate(data['createdAt']),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    docs[index].id,
                                    data['email'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isApproved &&
                              (actualOut != null || actualIn != null))
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (actualOut != null)
                                    Column(
                                      children: [
                                        const Text(
                                          "OUT",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "${actualOut.day}/${actualOut.month} ${actualOut.hour}:${actualOut.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (actualIn != null)
                                    Column(
                                      children: [
                                        const Text(
                                          "IN",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "${actualIn.day}/${actualIn.month} ${actualIn.hour}:${actualIn.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String docId,
    String? email,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Record"),
        content: Text(
          "Are you sure you want to delete this history record for '${email ?? 'Unknown'}'?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Record deleted successfully")),
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
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal Details Card
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final name = data?['name'] ?? 'Rector';
              final role = data?['role'] ?? 'Rector';
              final hostel = data?['assignedHostel'] ?? 'Unknown';
              final mobile = data?['mobile'] ?? 'Not set';

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF002244), Color(0xFF003366)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF002244).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002244),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$role • $hostel",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? "",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "Mobile: $mobile",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick Actions Section
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "QUICK ACTIONS",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.campaign,
                  label: 'Broadcast\nMessage',
                  color: Colors.orange,
                  onTap: () => _showBroadcastDialog(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.emergency,
                  label: 'Emergency\nContact',
                  color: Colors.red,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("calling security..."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Settings Section
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "SETTINGS",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  "New Leave Requests",
                  "Get notified for new applications",
                  true,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  "Late Entry Alerts",
                  "Notify when students are late",
                  true,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  onTap: () => _showChangePasswordDialog(context),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: "About App",
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Log Out",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPassController,
                      decoration: const InputDecoration(
                        labelText: "Current Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? "Enter current password" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPassController,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) => value!.length < 6
                          ? "Password must be 6+ chars"
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPassController,
                      decoration: const InputDecoration(
                        labelText: "Confirm New Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) => value != newPassController.text
                          ? "Passwords do not match"
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              final cred = EmailAuthProvider.credential(
                                email: user!.email!,
                                password: currentPassController.text,
                              );

                              // Re-authenticate
                              await user.reauthenticateWithCredential(cred);

                              // Update Password
                              await user.updatePassword(newPassController.text);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Password updated successfully",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBroadcastDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Broadcast Message"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  hintText: "e.g., Important Notice",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Message",
                  hintText: "Type your message here...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    messageController.text.isEmpty) {
                  return;
                }

                // Fetch user data to get hostel ID
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();
                final userData = userDoc.data();
                final hostelId = userData?['assignedHostel'];

                if (hostelId != null) {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                        'title': titleController.text.trim(),
                        'body': messageController.text.trim(),
                        'hostelId': hostelId,
                        'isGlobal': false,
                        'timestamp': FieldValue.serverTimestamp(),
                        'senderId': user.uid,
                        'senderRole': 'Rector',
                      });
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Broadcast sent successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002244),
                foregroundColor: Colors.white,
              ),
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                errorBuilder: (c, e, s) => const Icon(Icons.school),
              ),
              const SizedBox(width: 12),
              const Text("HostelLink"),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Version: 1.0.0"),
              SizedBox(height: 8),
              Text("Developer: RNGPIT Tech Team"),
              SizedBox(height: 16),
              Text(
                "A comprehensive hostel management solution for streamlining administrative tasks and enhancing student experience.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF002244),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF002244), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return SwitchListTile(
      value: value,
      onChanged: (val) {}, // Mock functionality
      activeTrackColor: const Color(0xFF002244),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }
}

class BlinkingUrgentBadge extends StatefulWidget {
  const BlinkingUrgentBadge({super.key});

  @override
  State<BlinkingUrgentBadge> createState() => _BlinkingUrgentBadgeState();
}

class _BlinkingUrgentBadgeState extends State<BlinkingUrgentBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              "URGENT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutStudentsListWidget extends StatelessWidget {
  final String? hostelId;
  const OutStudentsListWidget({super.key, this.hostelId});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('actualOutTime', isNull: false)
        .where('actualInTime', isNull: true);

    if (hostelId != null) {
      query = query.where('hostelId', isEqualTo: hostelId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('actualOutTime', descending: true).snapshots(),
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
                Icon(Icons.directions_walk, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No students are currently out",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
            final outTime = (data['actualOutTime'] as Timestamp).toDate();
            final expectedReturn = (data['endDate'] as Timestamp).toDate();
            final isOverdue = DateTime.now().isAfter(expectedReturn);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isOverdue
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.grey[200]!,
                  width: isOverdue ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isOverdue
                              ? Colors.red[50]
                              : Colors.blue[50],
                          child: Text(
                            (data['email'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: isOverdue
                                  ? Colors.red
                                  : const Color(0xFF002244),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['email'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isOverdue)
                                const Text(
                                  "OVERDUE RETURN",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "OUT",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeInfo("Out Time", outTime, Colors.black87),
                        _buildTimeInfo(
                          "Expected Return",
                          expectedReturn,
                          isOverdue ? Colors.red : Colors.grey[700]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Reason: ${data['reason'] ?? 'N/A'}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
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

  Widget _buildTimeInfo(String label, DateTime date, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class HostelStudentsTab extends StatefulWidget {
  final String? hostelId;
  const HostelStudentsTab({super.key, this.hostelId});

  @override
  State<HostelStudentsTab> createState() => _HostelStudentsTabState();
}

class _HostelStudentsTabState extends State<HostelStudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedBranch = "All";
  String _selectedYear = "All";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hostelId == null) {
      return const Center(child: Text("No Hostel Assigned"));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by name, email, or room...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 12),
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDropdown(
                      "Branch",
                      _selectedBranch,
                      ["All", "CS", "IT", "Mech", "Civil", "Elec"],
                      (val) => setState(() => _selectedBranch = val!),
                    ),
                    const SizedBox(width: 8),
                    _buildDropdown(
                      "Year",
                      _selectedYear,
                      ["All", "1", "2", "3", "4"],
                      (val) => setState(() => _selectedYear = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('student_imports')
                .where('assignedHostel', isEqualTo: widget.hostelId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No students found in this hostel"),
                );
              }

              // Client-side Filtering
              final students = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // 1. Search Query
                final email = (data['email'] ?? '').toString().toLowerCase();
                final name = (data['name'] ?? '').toString().toLowerCase();
                final room = (data['room'] ?? '').toString().toLowerCase();
                final matchesSearch =
                    _searchQuery.isEmpty ||
                    email.contains(_searchQuery) ||
                    name.contains(_searchQuery) ||
                    room.contains(_searchQuery);

                if (!matchesSearch) return false;

                // 2. Branch Filter
                final branch =
                    data['branch'] ?? 'CS'; // Default/Mock assumption
                if (_selectedBranch != "All" &&
                    !branch.toString().contains(_selectedBranch)) {
                  // Contains check for looser matching (e.g. 'Computer Engineering' contains 'Computer')
                  // But here we are matching specific codes if data uses codes, or text if text.
                  // Let's assume data matches options or is mappable.
                  // For now, simple exact or contains match if data is verbose
                  if (data['branch'] != _selectedBranch) return false;
                  // NOTE: If data has full names 'Computer Engineering', this might fail if filter is 'CS'.
                  // Ideally we map, but let's stick to direct compare or simple contains for now
                  // based on how data is stored.
                }

                // 3. Year Filter
                final year = data['year'] ?? '1';
                if (_selectedYear != "All" &&
                    year.toString() != _selectedYear) {
                  return false;
                }

                return true;
              }).toList();

              if (students.isEmpty) {
                return const Center(child: Text('No matches found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data = students[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Text(
                          (data['name'] ?? (data['email'] ?? 'S'))[0]
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF002244),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${data['email']}\nRoom: ${data['room'] ?? 'N/A'} • Year: ${data['year'] ?? 'N/A'} • ${data['branch'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.blueGrey),
                        onPressed: () =>
                            _confirmDelete(context, students[index].id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String validValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: validValue,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF002244)),
        style: const TextStyle(
          color: Color(0xFF002244),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value == "All" ? "$label: All" : value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Student"),
        content: const Text(
          "Are you sure you want to remove this student from the hostel list?\n\nThis will un-allocate the room.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('student_imports')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student removed successfully")),
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
  }
}
