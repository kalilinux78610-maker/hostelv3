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
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildComplaintsList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: const Color(0xFF002244),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', color: Colors.orange),
            const SizedBox(width: 8),
            _buildFilterChip('Resolved', color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {Color? color}) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = label);
      },
      selectedColor: color ?? Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? (color != null ? Colors.white : const Color(0xFF002244)) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          return const Center(child: Text('No complaints found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(26)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showResolveDialog(context, ref, complaint),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      complaint.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(complaint.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A1628)),
              ),
              const SizedBox(height: 6),
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
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.apartment_outlined, size: 14, color: Colors.grey[600]),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
              ),
              if (complaint.adminComment != null && complaint.adminComment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withAlpha(26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Comment:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.adminComment!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A5F)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                    initialValue: status,
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
