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
  String _selectedCategory = "All";
  String _selectedBranch = "All";
  final String _selectedYear = "All";
  bool _showPending = false; // Toggle for pending students

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: Column(
        children: [
          // Search & Filter Container
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1E3A), // Dark blue header
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Student Directory",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Manage and view student information",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.grid_view, color: Colors.white, size: 20),
                        tooltip: "Room Visualizer",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoomAvailabilityScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Toggle Button Stack
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildToggleButton(
                          "Active Students",
                          !_showPending,
                          Icons.people,
                          () => setState(() => _showPending = false),
                        ),
                      ),
                      Expanded(
                        child: _buildToggleButton(
                          "Pre-registered",
                          _showPending,
                          Icons.person_add,
                          () => setState(() => _showPending = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search by name, email, room or enrollment no...",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      _buildDropdown(
                        "Hostel",
                        _selectedHostel,
                        ["All", ...AppConfig.hostels],
                        Icons.apartment,
                        (val) => setState(() => _selectedHostel = val!),
                      ),
                      const SizedBox(width: 12),
                      _buildDropdown(
                        "Category",
                        _selectedCategory,
                        ["All", "Degree", "Diploma", "Pharmacy"],
                        Icons.category,
                        (val) => setState(() {
                          _selectedCategory = val!;
                          _selectedBranch = "All"; // Reset branch when category changes
                        }),
                      ),
                      const SizedBox(width: 12),
                      _buildDropdown(
                        "Branch",
                        _selectedBranch,
                        _selectedCategory == "All"
                            ? ["All", ...AppConfig.allBranches]
                            : ["All", ...AppConfig.getBranchesForCategory(_selectedCategory)],
                        Icons.school,
                        (val) => setState(() => _selectedBranch = val!),
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
                  // Format enrollment number robustly for search
                  final enrollStr = AppConfig.formatEnrollmentNo(data['enrollmentNo'], fallback: '');
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      email.contains(_searchQuery) ||
                      name.contains(_searchQuery) ||
                      room.contains(_searchQuery) ||
                      enrollStr.contains(_searchQuery);

                  if (!matchesSearch) return false;

                  // 2. Hostel Filter
                  if (_selectedHostel != "All") {
                    final String rawHostel = (data['assignedHostel'] ?? data['hostel'] ?? '').toString().trim();
                    if (rawHostel.isEmpty) return false;
                    // rawHostel can be a short code (NGP) or full name — handle both
                    final String resolvedFull = AppConfig.hostelCodes.containsKey(rawHostel)
                        ? rawHostel // it's already a full name key
                        : AppConfig.getFullHostelName(rawHostel); // convert short code to full name
                    if (resolvedFull != _selectedHostel) return false;
                  }

                  // 3. Branch Filter
                  if (_selectedBranch != "All") {
                    final branch = (data['branch'] ?? '').toString().trim();
                    if (branch.isEmpty) return false;
                    if (branch.toLowerCase() != _selectedBranch.toLowerCase()) return false;
                  }

                  // 4. Category Filter
                  if (_selectedCategory != "All") {
                    final cat = (data['category'] ?? '').toString().trim();
                    if (cat.isEmpty) return false;
                    if (cat.toLowerCase() != _selectedCategory.toLowerCase()) return false;
                  }

                  // 5. Year Filter
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
                  padding: const EdgeInsets.only(top: 16, bottom: 100),
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
      floatingActionButton: _showPending
          ? FloatingActionButton.extended(
              onPressed: _showAddStudentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF0052CC), // Bright blue
              foregroundColor: Colors.white,
            )
          : null,
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

  Widget _buildToggleButton(String label, bool isSelected, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF0052CC) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0052CC) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String validValue,
    List<String> options,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isExpanded: true,
            itemHeight: null, // Allow dynamic height for wrapping text
            value: validValue,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            selectedItemBuilder: (BuildContext context) {
              return options.map<Widget>((String value) {
                return Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF0052CC)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value == "All" ? "$label: All" : value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF0052CC)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          value == "All" ? "$label: All" : value,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
        ),
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
    final name = data['name'] ?? email.split('@')[0];
    final room = data['room'] ?? 'Not Assigned';
    final branch = data['branch'] ?? 'N/A';
    final program = data['program'] ?? '';
    final branchDisplay = program.isNotEmpty ? '$program - $branch' : branch;

    // Format enrollment number
    final enrollmentDisplay = AppConfig.formatEnrollmentNo(data['enrollmentNo'], fallback: '');

    final String rawHostel = data['assignedHostel'] ?? data['hostel'] ?? '';
    final String displayHostel = AppConfig.getFullHostelName(rawHostel);

    // Deterministic color from email hash
    final colors = [
      const Color(0xFF0052CC), // Blue
      const Color(0xFFFF5630), // Orange/Red
      const Color(0xFF36B37E), // Green
      const Color(0xFF6554C0), // Purple
      const Color(0xFF00B8D9), // Cyan
    ];
    final colorIndex = email.hashCode.abs() % colors.length;
    final themeColor = isPending ? Colors.orange : colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: themeColor, width: 4)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPending
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDetailScreen(uid: uid, data: data),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: themeColor.withValues(alpha: 0.1),
                      child: Icon(
                        isPending ? Icons.hourglass_empty : Icons.person,
                        color: themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPending) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  branchDisplay,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (enrollmentDisplay.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0052CC).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    enrollmentDisplay,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0052CC),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.meeting_room, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Room $room • $displayHostel",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _showEditStudentDialog(context, uid, data, isPending: isPending),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    if (onDelete != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: onDelete,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    if (!isPending)
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                      items: ['Degree', 'Diploma', 'Pharmacy']
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

  void _showEditStudentDialog(BuildContext context, String docId, Map<String, dynamic> currentData, {bool isPending = true}) {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final enrollmentNoController = TextEditingController(text: currentData['enrollmentNo'] ?? '');
    final emailController = TextEditingController(text: currentData['email'] ?? '');
    final instituteController = TextEditingController(text: currentData['institute'] ?? '');
    final departmentController = TextEditingController(text: currentData['branch'] ?? currentData['department'] ?? '');
    final roomController = TextEditingController(text: currentData['room'] ?? '');
    final floorController = TextEditingController(text: currentData['floor'] ?? '');
    final phoneController = TextEditingController(text: currentData['phone'] ?? currentData['contactNo'] ?? currentData['mobile'] ?? '');
    final fatherPhoneController = TextEditingController(text: currentData['fatherPhone'] ?? currentData['fatherMobile'] ?? currentData['parentContact'] ?? '');
    final motherPhoneController = TextEditingController(text: currentData['motherPhone'] ?? currentData['motherMobile'] ?? '');
    
    String? selectedGender = ['Male', 'Female', 'Other'].contains(currentData['gender']) ? currentData['gender'] : null;
    String? selectedBloodGroup = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(currentData['bloodGroup']) ? currentData['bloodGroup'] : null;
    String? selectedCategory = ['Degree', 'Diploma', 'Pharmacy'].contains(currentData['category']) ? currentData['category'] : null;
    String? selectedYear = ['1', '2', '3', '4'].contains(currentData['year']) ? currentData['year'] : null;
    
    // Determine existing hostel value (ensure it's a valid short code)
    String? existingHostelRaw = currentData['assignedHostel'] ?? currentData['hostel'];
    String? selectedHostel;
    if (existingHostelRaw != null) {
      if (AppConfig.hostelCodes.values.contains(existingHostelRaw)) {
        selectedHostel = existingHostelRaw;
      } else if (AppConfig.hostelCodes.containsKey(existingHostelRaw)) {
        selectedHostel = AppConfig.hostelCodes[existingHostelRaw];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isPending ? 'Edit Pre-registered Student' : 'Edit Active Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: enrollmentNoController, decoration: const InputDecoration(labelText: 'Enrollment No.')),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedGender,
                      isDense: true,
                      hint: const Text("Select Gender"),
                      items: ['Male', 'Female', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedGender = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBloodGroup,
                      isDense: true,
                      hint: const Text("Select Blood Group"),
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedBloodGroup = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (Required)'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: instituteController, decoration: const InputDecoration(labelText: 'Institute')),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Category'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isDense: true,
                      hint: const Text("Select Category"),
                      items: ['Degree', 'Diploma', 'Pharmacy'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: departmentController, decoration: const InputDecoration(labelText: 'Department / Branch')),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Year'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedYear,
                      isDense: true,
                      hint: const Text("Select Year"),
                      items: ['1', '2', '3', '4'].map((y) => DropdownMenuItem(value: y, child: Text("Year $y"))).toList(),
                      onChanged: (val) => setState(() => selectedYear = val),
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
                          .map((h) => DropdownMenuItem(value: h, child: Text(AppConfig.getFullHostelName(h))))
                          .toList(),
                      onChanged: (val) => setState(() => selectedHostel = val),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: floorController, decoration: const InputDecoration(labelText: 'Floor')),
                const SizedBox(height: 12),
                TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Room Number')),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'My Phone No.'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: fatherPhoneController, decoration: const InputDecoration(labelText: 'Father Mobile'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: motherPhoneController, decoration: const InputDecoration(labelText: 'Mother Mobile'), keyboardType: TextInputType.phone),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newEmail = emailController.text.trim();
                if (newEmail.isEmpty || !newEmail.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email')));
                  return;
                }
                
                try {
                  final newData = {
                    ...currentData,
                    'name': nameController.text.trim(),
                    'enrollmentNo': enrollmentNoController.text.trim(),
                    'gender': selectedGender,
                    'bloodGroup': selectedBloodGroup,
                    'email': newEmail,
                    'institute': instituteController.text.trim(),
                    'assignedHostel': selectedHostel,
                    'hostel': _getLongHostelName(selectedHostel),
                    'category': selectedCategory,
                    'branch': departmentController.text.trim(),
                    'year': selectedYear,
                    'floor': floorController.text.trim(),
                    'room': roomController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'mobile': phoneController.text.trim(), // Keep both in sync for active users
                    'fatherPhone': fatherPhoneController.text.trim(),
                    'fatherMobile': fatherPhoneController.text.trim(),
                    'motherPhone': motherPhoneController.text.trim(),
                    'motherMobile': motherPhoneController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (isPending) {
                    if (newEmail != docId) {
                      await FirebaseFirestore.instance.collection('student_imports').doc(newEmail).set(newData);
                      await FirebaseFirestore.instance.collection('student_imports').doc(docId).delete();
                    } else {
                      await FirebaseFirestore.instance.collection('student_imports').doc(docId).update(newData);
                    }
                  } else {
                    // For active students, update the users collection directly
                    await FirebaseFirestore.instance.collection('users').doc(docId).update(newData);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student details updated successfully!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002244),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
