import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const StudentDetailScreen({super.key, required this.uid, required this.data});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late bool _isFlagged;

  @override
  void initState() {
    super.initState();
    _isFlagged = widget.data['isFlagged'] == true;
  }

  Future<void> _toggleFlag() async {
    final newValue = !_isFlagged;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'isFlagged': newValue});

      setState(() {
        _isFlagged = newValue;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue ? 'Student Flagged' : 'Flag Removed'),
            backgroundColor: newValue ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.data['name']);
    final roomController = TextEditingController(text: widget.data['room']);
    final mobileController = TextEditingController(text: widget.data['mobile']);
    String? selectedHostel =
        widget.data['assignedHostel']; // Use consistent key
    String? selectedBranch = widget.data['branch'];
    String? selectedYear = widget.data['year'];

    // If assignedHostel is null, try fallback or default
    if (selectedHostel == null && widget.data['hostel'] != null) {
      selectedHostel = _getShortHostelCode(widget.data['hostel']);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Renamed dialogContext to context for clarity, shadowing parent
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Student Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(labelText: 'Room Number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  // Clean replacement for DropdownButtonFormField deprecation
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Assign Hostel',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _isValidHostel(selectedHostel)
                            ? selectedHostel
                            : null,
                        isDense: true,
                        items: ['BH1', 'BH2', 'BH3', 'BH4', 'GH1', 'GH2']
                            .map(
                              (h) => DropdownMenuItem(value: h, child: Text(h)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedHostel = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Branch'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBranch,
                        isDense: true,
                        items:
                            [
                                  'Computer Engineering',
                                  'Information Technology',
                                  'Mechanical Engineering',
                                  'Civil Engineering',
                                  'Electrical Engineering',
                                  'Chemical Engineering',
                                ]
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) =>
                            setState(() => selectedBranch = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Year'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedYear,
                        isDense: true,
                        items: ['1', '2', '3', '4']
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text("Year $y"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => selectedYear = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.uid)
                        .update({
                          'name': nameController.text.trim(),
                          'room': roomController.text.trim(),
                          'mobile': mobileController.text.trim(),
                          'assignedHostel': selectedHostel,
                          'hostel': _getLongHostelName(selectedHostel),
                          'branch': selectedBranch,
                          'year': selectedYear,
                        });

                    if (context.mounted) {
                      Navigator.pop(context); // Close Dialog

                      // Need to check PARENT context validity for next pop/snack
                      // We can't easily check parent 'context' validity here because it's shadowed.
                      // But 'widget' is available. `mounted` property of State refers to the Stateful Widget state.
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Student details updated!'),
                          ),
                        );
                        Navigator.pop(
                          this.context,
                        ); // Navigate back to directory
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002244),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isValidHostel(String? code) {
    return ['BH1', 'BH2', 'BH3', 'BH4', 'GH1', 'GH2'].contains(code);
  }

  String? _getShortHostelCode(String? fullName) {
    if (fullName == null) return null;
    if (fullName.contains('Boys Hostel 1')) return 'BH1';
    if (fullName.contains('Boys Hostel 2')) return 'BH2';
    if (fullName.contains('Boys Hostel 3')) return 'BH3';
    if (fullName.contains('Boys Hostel 4')) return 'BH4';
    if (fullName.contains('Girls Hostel 1')) return 'GH1';
    if (fullName.contains('Girls Hostel 2')) return 'GH2';
    return null; // or return fullName if it's already short code and valid
  }

  String _getLongHostelName(String? code) {
    switch (code) {
      case 'BH1':
        return 'Boys Hostel 1';
      case 'BH2':
        return 'Boys Hostel 2';
      case 'BH3':
        return 'Boys Hostel 3';
      case 'BH4':
        return 'Boys Hostel 4';
      case 'GH1':
        return 'Girls Hostel 1';
      case 'GH2':
        return 'Girls Hostel 2';
      default:
        return code ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build method variables ...
    final email = widget.data['email'] ?? 'Unknown';
    final name = widget.data['name'] ?? email.split('@')[0];
    final room = widget.data['room'] ?? 'N/A';
    final branch = widget.data['branch'] ?? 'N/A';
    final mobile = widget.data['mobile'] ?? 'N/A';
    final guardian = widget.data['guardian_name'] ?? 'N/A';
    final guardianMobile = widget.data['guardian_mobile'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Details',
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: Icon(_isFlagged ? Icons.flag : Icons.outlined_flag),
            color: _isFlagged ? Colors.red : Colors.white,
            tooltip: 'Flag Student',
            onPressed: _toggleFlag,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Profile
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _isFlagged
                        ? Colors.red[100]
                        : const Color(0xFF002244),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: _isFlagged ? Colors.red : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002244),
                    ),
                  ),
                  Text(email, style: TextStyle(color: Colors.grey[600])),
                  if (_isFlagged)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "FLAGGED FOR REVIEW",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details Cards
            _buildSectionHeader("Academic Info"),
            _buildInfoCard([
              _buildInfoRow(Icons.meeting_room, "Room No.", room),
              const Divider(),
              _buildInfoRow(
                Icons.school,
                "Branch/Year",
                "$branch / Year ${widget.data['year'] ?? ''}",
              ),
              const Divider(),
              _buildInfoRow(
                Icons.home,
                "Hostel",
                widget.data['hostel'] ??
                    (widget.data['assignedHostel'] != null
                        ? _getLongHostelName(widget.data['assignedHostel'])
                        : 'N/A'),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader("Contact Info"),
            _buildInfoCard([
              _buildInfoRow(Icons.phone, "Mobile", mobile),
              const Divider(),
              _buildInfoRow(Icons.person_outline, "Guardian", guardian),
              const Divider(),
              _buildInfoRow(
                Icons.phone_iphone,
                "Guardian Mobile",
                guardianMobile,
              ),
            ]),

            const SizedBox(height: 32),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Calling Student... (Simulated)"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call),
                    label: const Text("Call Student"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Calling Guardian... (Simulated)"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.family_restroom),
                    label: const Text("Call Parent"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002244),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF002244)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
