import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint_model.dart';
import '../repositories/complaint_repository.dart';

class AdminComplaintsScreen extends StatefulWidget {
  final String? hostelId; // Optional filter for Rectors

  const AdminComplaintsScreen({super.key, this.hostelId});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final _complaintRepository = ComplaintRepository();
  String _filter = 'All'; // 'All', 'Pending', 'Resolved'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16.0),
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
          Expanded(child: _buildComplaintsList()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {Color? color}) {
    final isSelected = _filter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = label;
        });
      },
      selectedColor: color ?? const Color(0xFF002244),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<List<Complaint>>(
      stream: _complaintRepository.getAllComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No complaints found'));
        }

        // Apply client-side filtering
        final complaints = snapshot.data!
            .where((complaint) {
              // 1. Hostel Filter
              if (widget.hostelId != null) {
                // Check if the complaint belongs to the assigned hostel
                return complaint.hostelId == widget.hostelId;
              }
              return true;
            })
            .where((complaint) {
              // 2. Status Filter
              if (_filter == 'All') return true;
              return complaint.status == _filter;
            })
            .toList();

        if (complaints.isEmpty) {
          return const Center(child: Text('No complaints match this filter'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            return _buildComplaintCard(complaint);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final isResolved = complaint.status == 'Resolved';
    final statusColor = isResolved ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showResolveDialog(complaint),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      complaint.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(complaint.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    complaint.userEmail,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    complaint.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResolveDialog(Complaint complaint) {
    final commentController = TextEditingController(
      text: complaint.adminComment,
    );
    String status = complaint.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text(
                          'Pending',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Resolved',
                        child: Text(
                          'Resolved',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        status = value!;
                      });
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
                      await _complaintRepository.updateComplaintStatus(
                        complaint.id,
                        status,
                        commentController.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      // Handle error
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
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
