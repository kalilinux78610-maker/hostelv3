import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'guard_scanner_screen.dart';
import 'guard_profile_screen.dart';

class GuardDashboardScreen extends StatefulWidget {
  const GuardDashboardScreen({super.key});

  @override
  State<GuardDashboardScreen> createState() => _GuardDashboardScreenState();
}

class _GuardDashboardScreenState extends State<GuardDashboardScreen> {
  final Color _primaryColor = const Color(0xFF002244);
  
  int _checkedInToday = 0;
  int _currentlyOut = 0;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    // 1. Currently Out
    FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'out')
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _currentlyOut = snapshot.docs.length);
    });

    // 2. Pending
    FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _pending = snapshot.docs.length);
    });

    // 3. Checked In Today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    FirebaseFirestore.instance
        .collection('leave_requests')
        .where('actualInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _checkedInToday = snapshot.docs.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 800;
    final bool isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWideScreen ? 800 : 500),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Hello,", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                                  const Text(
                                    "Guard",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuardProfileScreen())),
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person, color: Color(0xFF002244)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStatsCard(isSmallScreen),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isWideScreen ? 3 : (screenWidth < 320 ? 1 : 2),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWideScreen ? 1.2 : 1.0, 
                          children: [
                            _buildMenuCard(
                              icon: Icons.qr_code_scanner,
                              title: "QR Scan",
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuardScannerScreen())),
                            ),
                            _buildMenuCard(
                              icon: Icons.badge_outlined,
                              title: "GatePass ID",
                              subtitle: "Manual",
                              onTap: () => _showManualEntryDialog(),
                            ),
                            _buildMenuCard(
                              icon: Icons.history,
                              title: "History",
                              onTap: () {},
                            ),
                            _buildMenuCard(
                              icon: Icons.apartment,
                              title: "Details",
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: isSmall ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(count: "$_checkedInToday", label: "In", color: Colors.green, isSmall: isSmall),
          _buildStatItem(count: "$_currentlyOut", label: "Out", color: Colors.red, isSmall: isSmall),
          _buildStatItem(count: "$_pending", label: "Pending", color: Colors.orange, isSmall: isSmall),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String count, required String label, required Color color, required bool isSmall}) {
    double ringSize = isSmall ? 50 : 70;
    return Flexible(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(height: ringSize, width: ringSize, child: CircularProgressIndicator(value: 1.0, color: Colors.grey[100], strokeWidth: isSmall ? 5 : 8)),
              SizedBox(height: ringSize, width: ringSize, child: CircularProgressIndicator(value: count == "0" ? 0.05 : 0.75, color: color, backgroundColor: Colors.transparent, strokeWidth: isSmall ? 5 : 8, strokeCap: StrokeCap.round)),
              Text(count, style: TextStyle(fontSize: isSmall ? 16 : 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: isSmall ? 10 : 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
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
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryColor)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Manual Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: controller, decoration: const InputDecoration(labelText: "Student Enrollment ID", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processManualEntry(controller.text.trim());
              },
              child: const Text("SEARCH"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _processManualEntry(String id) async {
    if (id.isEmpty) return;
    try {
      final userQ = await FirebaseFirestore.instance.collection('users').where('enrollment', isEqualTo: id).limit(1).get();
      if (userQ.docs.isEmpty) return _showError("Student not found");
      
      final uid = userQ.docs.first.id;
      final name = userQ.docs.first['name'];
      
      final passQ = await FirebaseFirestore.instance.collection('leave_requests').where('userId', isEqualTo: uid).where('status', whereIn: ['approved', 'out']).orderBy('createdAt', descending: true).limit(1).get();
      if (passQ.docs.isEmpty) return _showError("No active pass for $name");
      
      _showVerificationDialog(passQ.docs.first.id, passQ.docs.first.data(), name, passQ.docs.first['status']);
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showVerificationDialog(String docId, Map<String, dynamic> data, String name, String status) {
    bool isOut = status == 'approved';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOut ? "Check-Out?" : "Check-In?"),
        content: Text("Student: $name\nReason: ${data['reason']}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () { Navigator.pop(context); _updatePass(docId, isOut); }, child: Text(isOut ? "OUT" : "IN")),
        ],
      ),
    );
  }

  Future<void> _updatePass(String docId, bool isOut) async {
    await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update({
      'status': isOut ? 'out' : 'completed',
      isOut ? 'actualOutTime' : 'actualInTime': FieldValue.serverTimestamp(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isOut ? "Checked OUT" : "Checked IN"), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }
}
