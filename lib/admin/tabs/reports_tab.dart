import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  String? _selectedHostel;
  final List<String> _hostels = [
    'Boys Hostel A',
    'Boys Hostel B',
    'Girls Hostel A',
    'Girls Hostel B',
  ]; // Example hostels

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hostel Operations Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002244),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _generatePdf(context),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text("Export"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002244),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hostel Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedHostel,
                hint: const Text("Select Hostel (All)"),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("All Hostels"),
                  ),
                  ..._hostels.map((hostel) {
                    return DropdownMenuItem(value: hostel, child: Text(hostel));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedHostel = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLiveStatsGrid(),
          const SizedBox(height: 24),
          const Text(
            'Complaint Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002244),
            ),
          ),
          const SizedBox(height: 12),
          _buildComplaintStats(),
        ],
      ),
    );
  }

  Widget _buildLiveStatsGrid() {
    Query outQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('actualOutTime', isNull: false)
        .where('actualInTime', isNull: true);

    Query pendingQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'pending');

    Query complaintsQuery = FirebaseFirestore.instance
        .collection('complaints')
        .where('status', isEqualTo: 'Pending');

    Query approvedQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'approved');

    if (_selectedHostel != null) {
      outQuery = outQuery.where('hostelId', isEqualTo: _selectedHostel);
      pendingQuery = pendingQuery.where('hostelId', isEqualTo: _selectedHostel);
      complaintsQuery = complaintsQuery.where(
        'hostelId',
        isEqualTo: _selectedHostel,
      );
      approvedQuery = approvedQuery.where(
        'hostelId',
        isEqualTo: _selectedHostel,
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          "Students OUT",
          outQuery.snapshots(),
          Colors.orange,
          Icons.directions_walk,
        ),
        _buildStatCard(
          "Pending Requests",
          pendingQuery.snapshots(),
          Colors.blue,
          Icons.pending_actions,
        ),
        _buildStatCard(
          "Pending Complaints",
          complaintsQuery.snapshots(),
          Colors.red,
          Icons.report_problem,
        ),
        _buildStatCard(
          "Approved Today",
          approvedQuery.snapshots(), // In real app, filter by date range
          Colors.green,
          Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildStatCard(
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
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplaintStats() {
    Query query = FirebaseFirestore.instance.collection('complaints');

    if (_selectedHostel != null) {
      query = query.where('hostelId', isEqualTo: _selectedHostel);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        final total = docs.length;
        if (total == 0) return const Text('No data');

        int maintenance = 0;
        int food = 0;
        int other = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = data['category'] ?? 'Other';
          if (cat == 'Maintenance') {
            maintenance++;
          } else if (cat == 'Food') {
            food++;
          } else {
            other++;
          }
        }

        return Card(
          elevation: 0,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBar("Maintenance", maintenance, total, Colors.blue),
                const SizedBox(height: 12),
                _buildBar("Food", food, total, Colors.orange),
                const SizedBox(height: 12),
                _buildBar("Other", other, total, Colors.purple),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBar(String label, int value, int total, Color color) {
    double percentage = total == 0 ? 0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("$value (${(percentage * 100).toStringAsFixed(0)}%)"),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    // Show Loading
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Generating Report...")));

    final pdf = pw.Document();

    // Fetch Data with Filtering
    Query outQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('actualOutTime', isNull: false)
        .where('actualInTime', isNull: true);

    Query pendingQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'pending');

    if (_selectedHostel != null) {
      outQuery = outQuery.where('hostelId', isEqualTo: _selectedHostel);
      pendingQuery = pendingQuery.where('hostelId', isEqualTo: _selectedHostel);
    }

    final outSnapshot = await outQuery.get();
    final pendingSnapshot = await pendingQuery.get();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Hostel Operations Report")),
              pw.SizedBox(height: 10),
              pw.Text(
                "Hostel: ${_selectedHostel ?? 'All Hostels'}",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text("Generated: ${DateTime.now().toString()}"),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                "Summary",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.Bullet(text: "Total Students Out: ${outSnapshot.docs.length}"),
              pw.Bullet(
                text: "Pending Leave Requests: ${pendingSnapshot.docs.length}",
              ),
              pw.SizedBox(height: 20),
              if (outSnapshot.docs.isNotEmpty) ...[
                pw.Text(
                  "Currently Out Students",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Email', 'Hostel', 'Out Time'],
                    ...outSnapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final outTime = (data['actualOutTime'] as Timestamp)
                          .toDate();
                      return [
                        data['email']?.toString() ?? 'N/A',
                        data['hostelId']?.toString() ?? 'N/A',
                        "${outTime.hour}:${outTime.minute}",
                      ];
                    }),
                  ],
                ),
              ] else
                pw.Text("No students are currently out."),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
