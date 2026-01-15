import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GatePassScreen extends StatelessWidget {
  const GatePassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const primaryColor = Color(0xFF002244);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Approve Gate Pass"),
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
              (user?.email?.split('@')[0] ?? "STUDENT");

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('leave_requests')
                .where('uid', isEqualTo: user?.uid)
                .where('status', isEqualTo: 'approved')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoActivePass();
              }

              final doc = snapshot.data!.docs.first;
              final data = doc.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPassCard(context, data, doc.id, user, userName),
                    const SizedBox(height: 20),
                    const Text(
                      "Show this QR code to the security guard",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoActivePass() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.report_problem, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "No Active Gate Pass",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Apply for leave and get approval first.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
    final leaveType = data['type'] ?? 'Outing';
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final reason = data['reason'] ?? 'N/A';

    // Formatting dates
    final startStr =
        "${startDate.day}/${startDate.month} ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')}";
    final endStr =
        "${endDate.day}/${endDate.month} ${endDate.hour}:${endDate.minute.toString().padLeft(2, '0')}";

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
              color: Color(0xFF002244),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: const Text(
              "OFFICIAL GATE PASS",
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
                // User Details
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

                // QR Code
                QrImageView(
                  data: docId, // The Document ID is used for verification
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 24),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    "APPROVED",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Details Grid
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
                      child: _buildDetailItem(
                        "Valid From",
                        startStr,
                        center: true,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem("Valid To", endStr, center: true),
                    ),
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
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
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
