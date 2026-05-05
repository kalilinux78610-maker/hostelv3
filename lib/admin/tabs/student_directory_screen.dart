import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'student_detail_screen.dart';
import 'room_availability_screen.dart';
import '../../app_config.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Filter States
  String _selectedHostel = "All";
  String _selectedBranch = "All";
  String _selectedYear = "All";
  bool _showPending = false; // Toggle for pending students

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // match dashboard
      body: Column(
        children: [
          // Search & Filter Container
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF002244),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Button for Active / Pending
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleButton(
                              "Active Students",
                              !_showPending,
                              () {
                                setState(() => _showPending = false);
                              },
                            ),
                            _buildToggleButton(
                              "Pre-registered",
                              _showPending,
                              () {
                                setState(() => _showPending = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.grid_view, color: Colors.white),
                        tooltip: "Room Visualizer",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RoomAvailabilityScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search by name, email, or room...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                        _buildDropdown(
                          "Hostel",
                          _selectedHostel,
                          ["All", ...AppConfig.hostels],
                          (val) => setState(() => _selectedHostel = val!),
                        ),
                      const SizedBox(width: 8),
                      _buildDropdown(
                        "Branch",
                        _selectedBranch,
                        ["All", ...AppConfig.allBranches],
                        (val) => setState(() => _selectedBranch = val!),
                      ),
                      const SizedBox(width: 8),
                      _buildDropdown(
                        "Year",
                        _selectedYear,
                        ["All", "1", "2", "3", "4"],
                        (val) => setState(() => _selectedYear = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _showPending
                  ? FirebaseFirestore.instance
                        .collection('student_imports')
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'student')
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      _showPending
                          ? 'No pre-registered students'
                          : 'No active students found',
                    ),
                  );
                }

                // Advanced Client-side filtering
                final students = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // 1. Search Query Check
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final room = (data['room'] ?? '').toString().toLowerCase();
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      email.contains(_searchQuery) ||
                      name.contains(_searchQuery) ||
                      room.contains(_searchQuery);

                  if (!matchesSearch) return false;

                  // 2. Hostel Filter
                  final String rawHostel = data['assignedHostel'] ?? data['hostel'] ?? '';
                  final String fullHostelName = rawHostel.isNotEmpty ? AppConfig.getFullHostelName(rawHostel) : AppConfig.hostels.first;
                  if (_selectedHostel != "All" && fullHostelName != _selectedHostel) {
                    return false;
                  }

                  // 3. Branch Filter
                  final branch = data['branch'] ?? 'CS'; // Default/Mock
                  if (_selectedBranch != "All" && branch != _selectedBranch) {
                    return false;
                  }

                  // 4. Year Filter
                  final year = data['year'] ?? '1'; // Default/Mock
                  if (_selectedYear != "All" &&
                      year.toString() != _selectedYear) {
                    return false;
                  }

                  return true;
                }).toList();

                if (students.isEmpty) {
                  return const Center(child: Text('No matches found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;
                    return _buildStudentCard(
                      context,
                      students[index].id,
                      data,
                      isPending: _showPending,
                      onDelete: () => _confirmDelete(
                        context,
                        students[index].id,
                        data,
                        _showPending,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    bool isPending,
  ) async {
    final email = data['email'] as String?;
    final name = data['name'] ?? email ?? 'Student';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Verification"),
        content: Text(
          "Are you sure you want to delete '$name'?\n\n"
          "This will permanently remove the record from the ${isPending ? 'Allocation List' : 'Application'}.\n"
          "${!isPending ? '(This also frees up the allocated slot)' : ''}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (isPending) {
          // Delete from student_imports
          await FirebaseFirestore.instance
              .collection('student_imports')
              .doc(docId)
              .delete();
        } else {
          // ACTIVE STUDENT DELETION (Complex)
          // 1. Delete from 'users'
          await FirebaseFirestore.instance
              .collection('users')
              .doc(docId)
              .delete();

          // 2. Also delete from 'student_imports' if email exists, to free the slot
          // Doc ID in student_imports is the email
          if (email != null) {
            await FirebaseFirestore.instance
                .collection('student_imports')
                .doc(email)
                .delete();
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student deleted successfully")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF002244) : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String validValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: validValue,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF002244)),
        style: const TextStyle(
          color: Color(0xFF002244),
          fontWeight: FontWeight.bold,
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value == "All" ? "$label: All" : value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> data, {
    bool isPending = false,
    VoidCallback? onDelete,
  }) {
    final email = data['email'] ?? 'Unknown';
    final name =
        data['name'] ?? email.split('@')[0]; // Fallback to email prefix
    final room = data['room'] ?? 'Not Assigned';
    final isFlagged = data['isFlagged'] == true;
    final branch = data['branch'] ?? 'N/A';
    final program = data['program'] ?? '';
    
    final branchDisplay = program.isNotEmpty ? '$program - $branch' : branch;

    // Hostel field logic: resolve full name from code
    final String rawHostel = data['assignedHostel'] ?? data['hostel'] ?? '';
    final String displayHostel = AppConfig.getFullHostelName(rawHostel);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPending
              ? Colors.orange.shade100
              : (isFlagged ? Colors.red[100] : const Color(0xFFE0E0E0)),
          child: Icon(
            isPending ? Icons.hourglass_empty : Icons.person,
            color: isPending
                ? Colors.orange
                : (isFlagged ? Colors.red : Colors.grey[600]),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$branchDisplay | $email"),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isPending) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      "Pre-registered",
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Room $room • $displayHostel",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete Student',
              ),
            if (!isPending) const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: isPending
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentDetailScreen(uid: uid, data: data),
                  ),
                );
              },
      ),
    );
  }

  void _showAddStudentDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final roomController = TextEditingController();
    final programController = TextEditingController();
    String? selectedCategory;
    String? selectedHostel;
    String? selectedBranch;
    String? selectedYear;
    String? selectedFeeStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Student (Pre-register)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "This creates a record so the student can Sign Up and get auto-verified.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Required)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: programController,
                  decoration: const InputDecoration(labelText: 'Program (e.g. B.Tech, B.Voc)'),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Category'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isDense: true,
                      hint: const Text("Select Category"),
                      items: ['Degree', 'Diploma']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCategory = val;
                          selectedBranch = null; // Reset branch when category changes
                        });
                      },
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
                      hint: const Text("Select Branch"),
                      items: AppConfig.getBranchesForCategory(selectedCategory)
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedBranch = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Assign Hostel'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedHostel,
                      isDense: true,
                      hint: const Text("Select Hostel"),
                      items: AppConfig.hostelCodes.values
                          .map(
                            (h) => DropdownMenuItem(value: h, child: Text(AppConfig.getFullHostelName(h))),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedHostel = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Year'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedYear,
                      isDense: true,
                      hint: const Text("Select Year"),
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
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fee Status'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFeeStatus,
                      isDense: true,
                      hint: const Text("Select Fee Status"),
                      items: ['Paid', 'Scholarship']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedFeeStatus = val),
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
                if (emailController.text.trim().isEmpty ||
                    !emailController.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('student_imports')
                      .doc(emailController.text.trim())
                      .set({
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'assignedHostel': selectedHostel,
                        'hostel': _getLongHostelName(selectedHostel),
                        'room': roomController.text.trim(),
                        'category': selectedCategory,
                        'program': programController.text.trim(),
                        'branch': selectedBranch,
                        'year': selectedYear,
                        'feeStatus': selectedFeeStatus,
                        'importedAt': FieldValue.serverTimestamp(),
                        'source': 'manual_admin_add',
                      });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Student Pre-registered! They will appear here after they Sign Up/Login.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002244),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  String _getLongHostelName(String? code) {
    if (code == null) return '';
    for (var entry in AppConfig.hostelCodes.entries) {
      if (entry.value == code) return entry.key;
    }
    return code;
  }
}
