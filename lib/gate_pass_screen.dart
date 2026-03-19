import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GatePassScreen extends StatefulWidget {
  const GatePassScreen({super.key});

  @override
  State<GatePassScreen> createState() => _GatePassScreenState();
}

class _GatePassScreenState extends State<GatePassScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Refresh every minute so validity status auto-updates
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const primaryColor = Color(0xFF002244);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gate Pass"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get(),
        builder: (context, userSnapshot) {
          final userName =
              userSnapshot.data?.get('name') ??
              (user?.email?.split('@')[0] ?? 'STUDENT');

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('leave_requests')
                .where('uid', isEqualTo: user?.uid)
                .where('status', isEqualTo: 'approved')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoActivePass(
                  "No Approved Leave",
                  "Apply for leave and get approval first.",
                );
              }

              // Find a leave that is currently valid (startDate <= now <= endDate)
              final docs = snapshot.data!.docs;
              QueryDocumentSnapshot? activeDoc;
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final start = (d['startDate'] as Timestamp).toDate();
                final end = (d['endDate'] as Timestamp).toDate();
                if (!_now.isBefore(start) && !_now.isAfter(end)) {
                  activeDoc = doc;
                  break;
                }
              }

              if (activeDoc == null) {
                // Check if there is a future leave coming up
                QueryDocumentSnapshot? upcomingDoc;
                for (final doc in docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final start = (d['startDate'] as Timestamp).toDate();
                  if (_now.isBefore(start)) {
                    upcomingDoc = doc;
                    break;
                  }
                }

                if (upcomingDoc != null) {
                  final d = upcomingDoc.data() as Map<String, dynamic>;
                  final start = (d['startDate'] as Timestamp).toDate();
                  final startStr =
                      "${start.day}/${start.month} ${start.hour}:${start.minute.toString().padLeft(2, '0')}";
                  return _buildNoActivePass(
                    "QR Not Yet Active",
                    "Your approved pass becomes valid on $startStr.",
                    icon: Icons.schedule,
                    color: Colors.orange,
                  );
                }

                return _buildNoActivePass(
                  "Pass Expired",
                  "Your leave period has ended. Apply again if needed.",
                  icon: Icons.timer_off_outlined,
                  color: Colors.red,
                );
              }

              final data = activeDoc.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPassCard(
                        context, data, activeDoc.id, user, userName),
                    const SizedBox(height: 16),
                    const Text(
                      "Show this QR code to the security guard",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Live validity countdown banner
                    _buildValidityBanner(data),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildValidityBanner(Map<String, dynamic> data) {
    final endDate = (data['endDate'] as Timestamp).toDate();
    final remaining = endDate.difference(_now);
    String timeLeft;
    if (remaining.inHours >= 1) {
      timeLeft = "${remaining.inHours}h ${remaining.inMinutes % 60}m remaining";
    } else {
      timeLeft = "${remaining.inMinutes} minutes remaining";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            timeLeft,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActivePass(
    String title,
    String subtitle, {
    IconData icon = Icons.qr_code_2,
    Color color = const Color(0xFF002244),
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 90, color: color.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    User? user,
    String userName,
  ) {
    const primaryColor = Color(0xFF002244);
    final leaveType = data['type'] ?? 'Outing';
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final reason = data['reason'] ?? 'N/A';

    String fmt(DateTime dt) =>
        "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text(
              "SVPES eGATE PASS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Student Name
                Text(
                  userName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  user?.uid.toUpperCase().substring(0, 8) ?? "ID",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code — only shown when time is valid (enforced by parent)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.5), width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: docId,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // VALID badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    "✓  VALID NOW",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Details
                Row(
                  children: [
                    Expanded(child: _buildDetailItem("Leave Type", leaveType)),
                    Expanded(child: _buildDetailItem("Reason", reason)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildDetailItem("Valid From", fmt(startDate),
                            center: true)),
                    Expanded(
                        child: _buildDetailItem("Valid To", fmt(endDate),
                            center: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool center = false}) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
