import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../repositories/notification_repository.dart';
import '../../domain/entities/complaint.dart';
import '../providers/complaint_provider.dart';

class AdminComplaintsScreen extends ConsumerStatefulWidget {
  final String? hostelId; // Optional filter for Rectors

  const AdminComplaintsScreen({super.key, this.hostelId});

  @override
  ConsumerState<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends ConsumerState<AdminComplaintsScreen> {
  String _filter = 'All'; // 'All', 'Pending', 'Resolved'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          _buildPremiumHeader(),
          Expanded(child: _buildComplaintsList()),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final complaintsAsync = ref.watch(allComplaintsProvider);
    int allCount = 0;
    int pendingCount = 0;
    int resolvedCount = 0;

    if (complaintsAsync.hasValue) {
      final allData = complaintsAsync.value!.where((c) => widget.hostelId == null || c.hostelId == widget.hostelId).toList();
      allCount = allData.length;
      pendingCount = allData.where((c) => c.status == 'Pending').length;
      resolvedCount = allData.where((c) => c.status == 'Resolved').length;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark Blue Background Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          decoration: const BoxDecoration(
            color: Color(0xFF0A1628),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -20,
                bottom: -40,
                child: Icon(Icons.announcement_rounded, size: 140, color: Colors.white.withAlpha(10)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Manage Complaints', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          'View, track and resolve student complaints',
                          style: TextStyle(color: Colors.blue[100], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.tune, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text("Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        // Floating Filter Bar
        Positioned(
          bottom: -25,
          left: 16,
          right: 16,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildFilterTab('All', allCount, Icons.check_circle, Colors.blue)),
                Container(width: 1, color: Colors.grey.withAlpha(30), height: 30),
                Expanded(child: _buildFilterTab('Pending', pendingCount, Icons.access_time_filled, Colors.orange)),
                Container(width: 1, color: Colors.grey.withAlpha(30), height: 30),
                Expanded(child: _buildFilterTab('Resolved', resolvedCount, Icons.check_circle_outline, Colors.green)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, int count, IconData icon, Color activeColor) {
    final isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? activeColor : Colors.grey),
              const SizedBox(width: 6),
              Text(
                '$label ($count)',
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return complaintsAsync.when(
      data: (allData) {
        final filteredData = allData.where((c) {
          if (widget.hostelId != null && c.hostelId != widget.hostelId) return false;
          if (_filter == 'All') return true;
          return c.status == _filter;
        }).toList();

        if (filteredData.isEmpty) {
          return const Center(child: Text('No complaints found', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
          itemCount: filteredData.length,
          itemBuilder: (context, index) => _ComplaintCard(complaint: filteredData[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _ComplaintCard extends ConsumerWidget {
  final ComplaintEntity complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isResolved = complaint.status == 'Resolved';
    final statusColor = isResolved ? Colors.green : Colors.orange;
    final statusBgColor = isResolved ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20);
    final commentBgColor = isResolved ? Colors.blue.withAlpha(15) : Colors.orange.withAlpha(15);
    final commentBorderColor = isResolved ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30);
    final commentTitleColor = isResolved ? Colors.blue[700]! : Colors.orange[800]!;
    final statusIcon = isResolved ? Icons.check_circle_outline : Icons.access_time;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        complaint.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM d, h:mm a').format(complaint.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showResolveDialog(context, ref, complaint),
                      borderRadius: BorderRadius.circular(20),
                      child: Icon(Icons.more_vert, size: 20, color: Colors.grey[500]),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${complaint.studentName ?? 'Unknown'} (${complaint.userBranch ?? 'N/A'})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(height: 12, width: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
                Icon(Icons.business, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Hostel: ${complaint.hostelId ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
            ),
            if (complaint.adminComment != null && complaint.adminComment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: commentBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: commentBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Comment:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: commentTitleColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.adminComment!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref, ComplaintEntity complaint) {
    final commentController = TextEditingController(text: complaint.adminComment);
    String status = complaint.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Complaint'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(color: Colors.orange))),
                      DropdownMenuItem(value: 'Resolved', child: Text('Resolved', style: TextStyle(color: Colors.green))),
                    ],
                    onChanged: (value) {
                      setDialogState(() => status = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Comment',
                      hintText: 'Action taken...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(complaintActionProvider.notifier).updateStatus(
                            complaint.id,
                            status,
                            commentController.text.trim(),
                          );

                      if (status == 'Resolved') {
                        await NotificationRepository().sendNotification(
                          title: "Complaint Resolved",
                          message: "Your complaint '${complaint.title}' has been marked as resolved.",
                          receiverUid: complaint.uid,
                          type: 'complaint_update',
                          relatedRequestId: complaint.id,
                        );
                      }

                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
