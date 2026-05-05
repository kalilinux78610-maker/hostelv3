import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'student_detail_screen.dart';
import 'room_availability_screen.dart';
import '../../services/auth_service.dart';

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
      backgroundColor: const Color(0xFF0D1E3A), // Dark blue background for header area
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: _buildScrollableContent(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
        backgroundColor: const Color(0xFF0D1E3A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1E3A), Color(0xFF163260)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage students and their information',
                      style: TextStyle(
                        color: Colors.blue[100],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => _buildLogoutDialog(ctx),
                    );
                    if (shouldLogout == true) await AuthService.signOut();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildToggleButton(
                        "Active Students",
                        Icons.people,
                        !_showPending,
                        () => setState(() => _showPending = false),
                      ),
                      const SizedBox(width: 8),
                      _buildToggleButton(
                        "Pre-registered",
                        Icons.person_add,
                        _showPending,
                        () => setState(() => _showPending = true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.grid_view, color: Colors.white),
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
        ],
      ),
    ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A3B7C) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blue[200]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blue[200],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildFiltersRow(),
        const SizedBox(height: 24),
        if (!_showPending) _buildRealtimeStatsCard(),
        if (!_showPending) const SizedBox(height: 24),
        _buildStudentsList(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      decoration: InputDecoration(
        hintText: "Search by name, email, or room number...",
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterDropdown(
            "Hostel",
            Icons.business,
            _selectedHostel,
            ["All", "Boys Hostel", "Girls Hostel"],
            (v) => setState(() => _selectedHostel = v!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            "Branch",
            Icons.school,
            _selectedBranch,
            ["All", "CS", "IT", "Mech", "Civil", "Elec"],
            (v) => setState(() => _selectedBranch = v!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            "Year",
            Icons.calendar_today,
            _selectedYear,
            ["All", "1", "2", "3", "4"],
            (v) => setState(() => _selectedYear = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String prefix,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
              style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w600),
              items: options.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(
                    e == "All" ? "$prefix: All" : e,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeStatsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int active = 0;
        int onLeave = 0;
        int inactive = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Determine dynamic status
            if (data['isFlagged'] == true || data['status'] == 'inactive') {
              inactive++;
            } else if (data['isOnLeave'] == true || data['status'] == 'on_leave') {
              onLeave++;
            } else {
              active++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.people, Colors.blue, total.toString(), 'Total Students'),
              _buildStatDivider(),
              _buildStatItem(Icons.check_circle_outline, Colors.green, active.toString(), 'Active'),
              _buildStatDivider(),
              _buildStatItem(Icons.access_time, Colors.orange, onLeave.toString(), 'On Leave'),
              _buildStatDivider(),
              _buildStatItem(Icons.person_off_outlined, Colors.red, inactive.toString(), 'Inactive'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, MaterialColor color, String count, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
          child: Icon(icon, color: color[600], size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _showPending
          ? FirebaseFirestore.instance.collection('student_imports').snapshots()
          : FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_showPending ? 'No pre-registered students' : 'No active students found'),
            ),
          );
        }

        // Apply client-side filters
        final students = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Search Query Check
          final email = (data['email'] ?? '').toString().toLowerCase();
          final name = (data['name'] ?? '').toString().toLowerCase();
          final room = (data['room'] ?? '').toString().toLowerCase();
          final matchesSearch = _searchQuery.isEmpty ||
              email.contains(_searchQuery) ||
              name.contains(_searchQuery) ||
              room.contains(_searchQuery);

          if (!matchesSearch) return false;

          // Hostel Filter
          final hostel = data['hostel'] ?? 'Boys Hostel';
          if (_selectedHostel != "All" && hostel != _selectedHostel) {
            if (_selectedHostel == "Boys Hostel" && !hostel.toString().contains("Boys")) return false;
            if (_selectedHostel == "Girls Hostel" && !hostel.toString().contains("Girls")) return false;
          }

          // Branch Filter
          final branch = data['branch'] ?? 'CS';
          if (_selectedBranch != "All" && branch != _selectedBranch) return false;

          // Year Filter
          final year = data['year'] ?? '1';
          if (_selectedYear != "All" && year.toString() != _selectedYear) return false;

          return true;
        }).toList();

        if (students.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No matches found')));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Students (${students.length})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text("Sort by: Name A-Z", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...students.map((doc) => _buildStudentCard(context, doc.id, doc.data() as Map<String, dynamic>)),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(BuildContext context, String uid, Map<String, dynamic> data) {
    final email = data['email'] ?? 'Unknown';
    final name = data['name'] ?? email.split('@')[0];
    final room = data['room'] ?? 'N/A';
    final branch = data['branch'] ?? 'N/A';
    
    String hostelShort = data['assignedHostel'] ?? data['hostel'] ?? 'N/A';
    if (hostelShort.length > 5) {
      if (hostelShort.contains("Boys")) hostelShort = "BH1"; // Mock short name
      else if (hostelShort.contains("Girls")) hostelShort = "GH1";
    }

    String initials = "ST";
    if (name.toString().trim().isNotEmpty) {
      List<String> parts = name.toString().trim().split(" ");
      if (parts.length > 1) {
        initials = parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    // Determine status for UI
    String status = "Active";
    Color statusColor = Colors.green;
    
    if (_showPending) {
      status = "Pre-reg";
      statusColor = Colors.orange;
    } else if (data['isFlagged'] == true || data['status'] == 'inactive') {
      status = "Inactive";
      statusColor = Colors.grey;
    } else if (data['isOnLeave'] == true || data['status'] == 'on_leave') {
      status = "On Leave";
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showPending
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(uid: uid, data: data),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[50],
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Room $room • $hostelShort • $branch",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          CircleAvatar(radius: 3, backgroundColor: statusColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    // Keep the existing add student dialog logic to maintain functionality
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final roomController = TextEditingController();
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
                  decoration: const InputDecoration(labelText: 'Email (Required)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Category'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isDense: true,
                      hint: const Text("Select Category"),
                      items: ['Degree', 'Diploma'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCategory = val;
                          selectedBranch = null;
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
                      items: (selectedCategory == 'Degree'
                              ? ['IT & MSC-IT', 'B.VOC', 'CSE', 'BBA & MBA', 'Chemical', 'Electrical', 'Pharmacy', 'Civil Engineering']
                              : selectedCategory == 'Diploma'
                                  ? ['Electrical Engineering', 'Chemical Engineering', 'Information Technology', 'Computer Engineering', 'Mechanical Engineering']
                                  : <String>[])
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
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
                      items: ['BH1', 'BH2', 'BH3', 'BH4', 'GH1', 'GH2'].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
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
                      items: ['1', '2', '3', '4'].map((y) => DropdownMenuItem(value: y, child: Text("Year $y"))).toList(),
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
                      items: ['Paid', 'Scholarship'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
                if (emailController.text.trim().isEmpty || !emailController.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email')));
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('student_imports').doc(emailController.text.trim()).set({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'assignedHostel': selectedHostel,
                    'hostel': _getLongHostelName(selectedHostel),
                    'room': roomController.text.trim(),
                    'category': selectedCategory,
                    'branch': selectedBranch,
                    'year': selectedYear,
                    'feeStatus': selectedFeeStatus,
                    'importedAt': FieldValue.serverTimestamp(),
                    'source': 'manual_admin_add',
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student Pre-registered! They will appear here after they Sign Up/Login.'), duration: Duration(seconds: 4)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1E3A), foregroundColor: Colors.white),
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  String _getLongHostelName(String? code) {
    switch (code) {
      case 'BH1': return 'Boys Hostel 1';
      case 'BH2': return 'Boys Hostel 2';
      case 'BH3': return 'Boys Hostel 3';
      case 'BH4': return 'Boys Hostel 4';
      case 'GH1': return 'Girls Hostel 1';
      case 'GH2': return 'Girls Hostel 2';
      default: return code ?? '';
    }
  }

  // Same logout dialog from dashboard to keep UI consistent
  Widget _buildLogoutDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.15),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Logging Out?', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            Text('Are you sure you want to\nlog out of your account?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                      child: const Text('Cancel', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Log Out', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
}
