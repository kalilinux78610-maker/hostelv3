import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../app_config.dart';
import 'attendance_reports_screen.dart';
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
  final List<String> _hostels = AppConfig.hostels;

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
            'Attendance & Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002244),
            ),
          ),
          const SizedBox(height: 12),
          _buildAttendanceReportLink(context),
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
      final code = AppConfig.getHostelCode(_selectedHostel!);
      outQuery = outQuery.where('hostelId', isEqualTo: code);
      pendingQuery = pendingQuery.where('hostelId', isEqualTo: code);
      complaintsQuery = complaintsQuery.where(
        'hostelId',
        isEqualTo: code,
      );
      approvedQuery = approvedQuery.where(
        'hostelId',
        isEqualTo: code,
      );
    } else {
      // Exclude passed records if necessary, though status handles it
      outQuery = outQuery.where(
        'hostelId',
        isNotEqualTo: null,
      );
      pendingQuery = pendingQuery.where(
        'hostelId',
        isNotEqualTo: null,
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
          onTap: (ctx) => _showDetailsSheet(ctx, "Students Currently OUT", outQuery.snapshots(), 'leave'),
        ),
        _buildStatCard(
          "Pending Requests",
          pendingQuery.snapshots(),
          Colors.blue,
          Icons.pending_actions,
          onTap: (ctx) => _showDetailsSheet(ctx, "Pending Requests", pendingQuery.snapshots(), 'leave'),
        ),
        _buildStatCard(
          "Pending Complaints",
          complaintsQuery.snapshots(),
          Colors.red,
          Icons.report_problem,
          onTap: (ctx) => _showDetailsSheet(ctx, "Pending Complaints", complaintsQuery.snapshots(), 'complaint'),
        ),
        _buildStatCard(
          "Approved Today",
          approvedQuery.snapshots(),
          Colors.green,
          Icons.check_circle,
          onTap: (ctx) => _showDetailsSheet(ctx, "Approved Requests", approvedQuery.snapshots(), 'leave'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    Stream<QuerySnapshot> stream,
    Color color,
    IconData icon, {
    void Function(BuildContext)? onTap,
    bool todayOnly = false,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          if (todayOnly) {
            final now = DateTime.now();
            count = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = (data['startDate'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
              if (ts == null) return false;
              final date = ts.toDate();
              return date.year == now.year && date.month == now.month && date.day == now.day;
            }).length;
          } else {
            count = snapshot.data!.docs.length;
          }
        }
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap != null ? () => onTap(context) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
            ),
          ),
        );
      },
    );
  }

  void _showDetailsSheet(BuildContext context, String title, Stream<QuerySnapshot> stream, String type, {bool todayOnly = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF002244))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No records found."));
                  }
                  
                  List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();
                  
                  if (todayOnly) {
                    final now = DateTime.now();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ts = (data['startDate'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
                      if (ts == null) return false;
                      final date = ts.toDate();
                      return date.year == now.year && date.month == now.month && date.day == now.day;
                    }).toList();
                  }

                  // Sort by createdAt descending
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTs = aData['createdAt'] as Timestamp?;
                    final bTs = bData['createdAt'] as Timestamp?;
                    if (aTs == null || bTs == null) return 0;
                    return bTs.compareTo(aTs);
                  });

                  if (docs.isEmpty) {
                    return const Center(child: Text("No records found for today."));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      if (type == 'leave') {
                        final email = data['email']?.toString() ?? 'Unknown';
                        final name = data['name']?.toString() ?? email.split('@')[0];
                        final reason = data['reason']?.toString() ?? 'No reason provided';
                        final status = data['status']?.toString().toUpperCase() ?? 'UNKNOWN';
                        Color statusColor = Colors.grey;
                        if (status == 'APPROVED') statusColor = Colors.green;
                        if (status == 'PENDING') statusColor = Colors.orange;
                        if (status == 'REJECTED') statusColor = Colors.red;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(reason, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      } else if (type == 'complaint') {
                        final titleStr = data['title']?.toString() ?? 'Complaint';
                        final cat = data['category']?.toString() ?? 'Other';
                        final desc = data['description']?.toString() ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: const Icon(Icons.report_problem, color: Colors.red),
                          ),
                          title: Text(titleStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("$cat - $desc", maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        );
                      }
                      return const SizedBox();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintStats() {
    Query query = FirebaseFirestore.instance.collection('complaints');

    if (_selectedHostel != null) {
      query = query.where('hostelId', isEqualTo: AppConfig.getHostelCode(_selectedHostel!));
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

    Query complaintsQuery = FirebaseFirestore.instance
        .collection('complaints')
        .where('status', isEqualTo: 'Pending');

    Query approvedQuery = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('status', isEqualTo: 'approved');

    if (_selectedHostel != null) {
      final code = AppConfig.getHostelCode(_selectedHostel!);
      outQuery = outQuery.where('hostelId', isEqualTo: code);
      pendingQuery = pendingQuery.where('hostelId', isEqualTo: code);
      complaintsQuery = complaintsQuery.where('hostelId', isEqualTo: code);
      approvedQuery = approvedQuery.where('hostelId', isEqualTo: code);
    }

    final outSnapshot = await outQuery.get();
    final pendingSnapshot = await pendingQuery.get();
    final complaintsSnapshot = await complaintsQuery.get();
    final approvedSnapshot = await approvedQuery.get();

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
              pw.Bullet(text: "Pending Leave Requests: ${pendingSnapshot.docs.length}"),
              pw.Bullet(text: "Pending Complaints: ${complaintsSnapshot.docs.length}"),
              pw.Bullet(text: "Approved Leave Requests: ${approvedSnapshot.docs.length}"),
              pw.SizedBox(height: 20),
              
              if (outSnapshot.docs.isNotEmpty) ...[
                pw.Text("Currently Out Students", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Email', 'Hostel', 'Out Time'],
                    ...outSnapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final outTime = (data['actualOutTime'] as Timestamp).toDate();
                      return [
                        data['email']?.toString() ?? 'N/A',
                        data['hostelId']?.toString() ?? 'N/A',
                        "${outTime.hour.toString().padLeft(2, '0')}:${outTime.minute.toString().padLeft(2, '0')}",
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],

              if (pendingSnapshot.docs.isNotEmpty) ...[
                pw.Text("Pending Leave Requests", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Name', 'Reason', 'Hostel'],
                    ...pendingSnapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return [
                        data['name']?.toString() ?? 'N/A',
                        data['reason']?.toString() ?? 'N/A',
                        data['hostelId']?.toString() ?? 'N/A',
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],

              if (complaintsSnapshot.docs.isNotEmpty) ...[
                pw.Text("Pending Complaints", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Title', 'Category', 'Hostel'],
                    ...complaintsSnapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return [
                        data['title']?.toString() ?? 'N/A',
                        data['category']?.toString() ?? 'N/A',
                        data['hostelId']?.toString() ?? 'N/A',
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],

              if (approvedSnapshot.docs.isNotEmpty) ...[
                pw.Text("Approved Leave Requests", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Name', 'Type', 'Hostel'],
                    ...approvedSnapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return [
                        data['name']?.toString() ?? 'N/A',
                        data['type']?.toString() ?? 'N/A',
                        data['hostelId']?.toString() ?? 'N/A',
                      ];
                    }),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildAttendanceReportLink(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AttendanceReportsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF002244), Color(0xFF004488)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.white, size: 40),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Attendance History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "View detailed present/absent logs by date",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
