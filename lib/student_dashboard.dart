import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'apply_leave_screen.dart';
import 'gate_pass_screen.dart';
import 'features/complaints/presentation/screens/student_complaints_screen.dart';
import 'mess_menu_screen.dart';
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

        // Extract Data — multiple fallbacks to handle different field names
        final name = userData?['name'] ??
            userData?['fullName'] ??
            userData?['displayName'] ??
            user.displayName ??
            "Student";

        final room = userData?['room'] ??
            userData?['roomNumber'] ??
            userData?['roomNo'] ??
            "N/A";

        final hostel = userData?['assignedHostel'] ??
            userData?['hostel'] ??
            userData?['hostelName'] ??
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
                        const SizedBox(height: 28),

                        // My Latest Request
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _RecentRequestsList(uid: user.uid),
                        ),
                        const SizedBox(height: 28),

                        // Today's Mess Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _TodayMessCard(),
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
            } else if (item['label'] == 'Mess Menu') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessMenuScreen()),
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
  // Rebuild every 30s so rejected cards disappear on time
  late final Stream<int> _ticker;

  // Tracks when each rejected doc was first observed in the UI
  final Map<String, DateTime> _rejectedFirstSeen = {};

  // Locally track IDs being dismissed (to avoid flicker before Firestore updates)
  final Set<String> _pendingDismiss = {};

  // How long a rejected card stays visible before disappearing
  static const _rejectedVisibleDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 30), (i) => i);
  }

  /// Filter requests — returns maps with 'docId' + all data fields.
  /// - 'completed' / 'cancelled' → skip
  /// - Active (pending/approved/out) → show the most recent non-expired one
  /// - 'rejected' → show for 5 minutes, then auto-disappear
  List<Map<String, dynamic>> _filterRequests(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();

    // Sort newest first
    final sorted = List<QueryDocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    // Find the newest createdAt across ALL docs (any status)
    // Used to detect if a newer request exists after a rejected one
    DateTime newestOverall = DateTime(2000);
    for (final doc in sorted) {
      final raw = doc.data() as Map<String, dynamic>;
      final t = (raw['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      if (t.isAfter(newestOverall)) newestOverall = t;
    }

    Map<String, dynamic>? activeRequest;
    final List<Map<String, dynamic>> rejectedRequests = [];

    for (final doc in sorted) {
      final raw = doc.data() as Map<String, dynamic>;
      final data = {'docId': doc.id, ...raw};
      final status = (raw['status'] ?? '').toString();
      final endDate = (raw['endDate'] as Timestamp?)?.toDate();
      final docTime = (raw['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);

      // Skip finished / cancelled / dismissed entries
      if (status == 'completed' || status == 'cancelled' || status == 'dismissed') continue;

      if (status == 'rejected') {
        // Hide if student permanently dismissed it (Firestore or pending)
        if (_pendingDismiss.contains(doc.id)) continue;

        // Hide rejected card immediately if ANY newer request was created after it
        final hasNewerRequest = newestOverall.isAfter(docTime);
        if (hasNewerRequest) continue;

        // No newer request exists — show for 5 minutes so student sees the outcome
        _rejectedFirstSeen.putIfAbsent(doc.id, () => now);
        final elapsed = now.difference(_rejectedFirstSeen[doc.id]!);
        if (elapsed < _rejectedVisibleDuration) {
          rejectedRequests.add(data);
        }
        continue;
      }

      // Active: pending / approved / out
      if (status == 'pending' || status == 'approved' || status == 'out') {
        if (endDate != null && endDate.isBefore(now)) continue;
        activeRequest ??= data;
      }
    }

    return [
      if (activeRequest != null) activeRequest,
      // Only show rejected if no active request AND no newer request of any kind
      if (activeRequest == null) ...rejectedRequests,
    ];
  }

  /// Permanently dismiss a rejected card by updating Firestore status to 'dismissed'
  Future<void> _dismissRejected(String docId) async {
    // Immediately hide from UI (optimistic update)
    setState(() => _pendingDismiss.add(docId));
    try {
      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .update({'status': 'dismissed'});
    } catch (e) {
      // If Firestore fails, keep it hidden in this session via _pendingDismiss
      debugPrint('Dismiss failed: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: double.infinity,
          child: Text(
            "My Latest Request",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream: _ticker,
          builder: (context, _) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leave_requests')
                  .where('uid', isEqualTo: widget.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("Dashboard Query Error: \${snapshot.error}");
                  return const Text("Error loading requests");
                }
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
                  children: filtered
                      .map((data) => _buildRequestCard(context, data))
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> data) {
    final status   = (data['status'] ?? '').toString();
    final hodStatus    = (data['hodStatus'] ?? '').toString();
    final wardenStatus = (data['wardenStatus'] ?? '').toString();
    final rectorStatus = (data['rectorStatus'] ?? '').toString();
    final docId    = data['docId'] as String?;
    final type     = data['type'] ?? 'Leave';
    final bool canCancel = status == 'pending';

    // Date range label
    String dateRange = '';
    final start = (data['startDate'] as Timestamp?)?.toDate();
    final end   = (data['endDate']   as Timestamp?)?.toDate();
    if (start != null && end != null) {
      String fmt(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';
      dateRange = '${fmt(start)} – ${fmt(end)}';
    }

    // Overall status badge
    String badgeLabel;
    Color  badgeColor;
    Color  badgeBg;
    if (status == 'rejected') {
      badgeLabel = 'REJECTED'; badgeColor = Colors.red; badgeBg = const Color(0xFFFFE5E5);
    } else if (status == 'approved' || status == 'out' || status == 'completed') {
      badgeLabel = 'APPROVED'; badgeColor = const Color(0xFF1A7A5E); badgeBg = const Color(0xFFD0F5EA);
    } else {
      badgeLabel = 'PENDING';  badgeColor = const Color(0xFFFF6B00); badgeBg = const Color(0xFFFFF0E6);
    }

    // Stepper step states: 0=waiting, 1=active/pending, 2=done, 3=rejected
    int hodStep, wardenStep, rectorStep;

    final isOuting = type.toLowerCase().contains('outing');

    if (isOuting) {
      // Outing: only Rector matters
      hodStep    = 2; // bypassed → show as done
      wardenStep = 2;
      if (status == 'rejected')      { rectorStep = 3; }
      else if (rectorStatus == 'approved' || status == 'approved') { rectorStep = 2; }
      else { rectorStep = 1; }
    } else {
      // Home leave
      if (status == 'rejected') {
        hodStep    = hodStatus == 'approved' ? 2 : 3;
        wardenStep = hodStatus == 'approved' && wardenStatus != 'approved' ? 3 : (wardenStatus == 'approved' ? 2 : 0);
        rectorStep = 3;
      } else {
        hodStep    = hodStatus == 'approved' ? 2 : (hodStatus == 'pending' ? 1 : 0);
        wardenStep = hodStatus != 'approved' ? 0
                   : wardenStatus == 'approved' ? 2
                   : wardenStatus == 'pending'  ? 1 : 0;
        rectorStep = wardenStatus != 'approved' ? 0
                   : rectorStatus == 'approved' || status == 'approved' ? 2
                   : rectorStatus == 'pending'  ? 1 : 0;
      }
    }

    final isRejected = status == 'rejected';

    Widget cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: type + badge ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              // Badge (with right padding to leave room for X button on rejected)
              Padding(
                padding: EdgeInsets.only(right: isRejected ? 28.0 : 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (dateRange.isNotEmpty) ...
            [
              const SizedBox(height: 4),
              Text(
                dateRange,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],

          const SizedBox(height: 18),

          // ── Stepper ─────────────────────────────────────────────
          if (!isOuting)
            _buildStepper(hodStep, wardenStep, rectorStep)
          else
            _buildOutingStepper(rectorStep),

          // ── Cancel button ────────────────────────────────────────
          if (canCancel && docId != null) ...
            [
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _confirmCancel(context, docId),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined, size: 15, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'Cancel Request',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );

    // Wrap rejected card in a Stack with dismiss X button
    if (isRejected && docId != null) {
      return Stack(
        children: [
          cardWidget,
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _dismissRejected(docId),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return cardWidget;
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  /// step: 0=waiting(grey) 1=active/pending(orange) 2=done(green) 3=rejected(red)
  Widget _buildStepper(int hod, int warden, int rector) {
    final labels = ['HOD', 'WARDEN', 'RECTOR'];
    final steps  = [hod, warden, rector];
    return _stepperRow(labels, steps);
  }

  Widget _buildOutingStepper(int rector) {
    return _stepperRow(['RECTOR'], [rector]);
  }

  Widget _stepperRow(List<String> labels, List<int> steps) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isLast = i == labels.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _stepCircle(steps[i]),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: _stepLabelColor(steps[i]),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: steps[i] == 2
                        ? const Color(0xFF1A7A5E)
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _stepCircle(int step) {
    Color bg;
    Widget child;
    switch (step) {
      case 2: // done
        bg    = const Color(0xFF1A7A5E);
        child = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
      case 1: // active / pending
        bg    = const Color(0xFFFF6B00);
        child = const Icon(Icons.hourglass_bottom, color: Colors.white, size: 16);
        break;
      case 3: // rejected
        bg    = Colors.grey;
        child = const Icon(Icons.close, color: Colors.white, size: 16);
        break;
      default: // waiting
        bg    = Colors.grey[300]!;
        child = Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      child: child,
    );
  }

  Color _stepLabelColor(int step) {
    if (step == 2) return const Color(0xFF1A7A5E);
    if (step == 1) return const Color(0xFFFF6B00);
    return Colors.grey;
  }

  /// Shows a confirm dialog, then sets status to 'cancelled'
  Future<void> _confirmCancel(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Cancel Request?"),
          ],
        ),
        content: const Text(
          "Are you sure you want to cancel this request?\n"
          "You will be able to submit a new one after cancelling.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No, Keep It"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(docId)
            .update({'status': 'cancelled'});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled. You can now submit a new one.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ============================================================
// TODAY'S MESS CARD — Student Dashboard
// ============================================================
class _TodayMessCard extends StatefulWidget {
  @override
  State<_TodayMessCard> createState() => _TodayMessCardState();
}

class _TodayMessCardState extends State<_TodayMessCard> {
  static const Color _orange = Color(0xFFFF6B00);

  // Meal tabs
  final List<String> _meals = ['Breakfast', 'Lunch', 'Dinner'];
  int _selectedMeal = 0;

  // Meal time labels
  final Map<String, String> _mealTimes = {
    'Breakfast': '8:00 AM – 9:00 AM',
    'Lunch': '12:00 PM – 1:30 PM',
    'Dinner': '7:00 PM – 8:00 PM',
  };

  // Pick current meal automatically based on time
  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 15) {
      _selectedMeal = 1; // Lunch
    } else if (hour >= 19) {
      _selectedMeal = 2; // Dinner
    } else {
      _selectedMeal = 0; // Breakfast
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('mess_menu')
          .snapshots(),
      builder: (context, snapshot) {
        // Get today's day name
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final today = days[DateTime.now().weekday - 1];

        Map<String, dynamic> dayData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          final allData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          dayData = allData[today] as Map<String, dynamic>? ?? {};
        }

        final mealKey = _meals[_selectedMeal];
        final mealText = dayData[mealKey] as String? ?? '';
        final imageUrl = dayData['${mealKey}_imageUrl'] as String? ?? '';
        final mealTime = _mealTimes[mealKey] ?? '';

        // Parse comma-separated items into list
        final items = mealText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: "Today's Mess" + "FULL MENU"
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Mess",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessMenuScreen(),
                        ),
                      ),
                      child: const Text(
                        'FULL MENU',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Meal Tabs: Breakfast | Lunch | Dinner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_meals.length, (i) {
                      final isSelected = _selectedMeal == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMeal = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? _orange : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _meals[i].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    );
                  }),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Food Photo
              if (imageUrl.isNotEmpty)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Image.network(
                        imageUrl,
                        height: 185,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _noPhotoPlaceholder(),
                      ),
                    ),
                    // Gradient overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Meal name + time on photo
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealKey == 'Breakfast'
                                ? 'Morning Breakfast'
                                : mealKey == 'Lunch'
                                    ? 'Maharaja Thali'
                                    : 'Evening Dinner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Served from $mealTime',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                _noPhotoPlaceholder(),

              const SizedBox(height: 14),

              // Food Items List
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Menu not set for today',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _noPhotoPlaceholder() {
    return Container(
      height: 140,
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 36, color: Colors.grey[300]),
            const SizedBox(height: 6),
            Text(
              'No photo yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
