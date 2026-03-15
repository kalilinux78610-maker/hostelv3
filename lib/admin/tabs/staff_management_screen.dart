import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/staff_model.dart';
import '../../repositories/staff_repository.dart';

// --- Screen 1: The Grid Dashboard --- //
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _repository = StaffRepository();
  bool _isLoading = false;

  Future<void> _seedDefaultStaff() async {
    setState(() => _isLoading = true);
    try {
      final List<StaffMember> defaults = [
        StaffMember(
          id: 'rector.bh1@hostel.com',
          name: 'Rector BH1',
          role: 'Rector',
          mobile: '9999999991',
          email: 'rector.bh1@hostel.com',
          isActive: true,
          assignedHostel: 'BH1',
        ),
        StaffMember(
          id: 'rector.bh2@hostel.com',
          name: 'Rector BH2',
          role: 'Rector',
          mobile: '9999999992',
          email: 'rector.bh2@hostel.com',
          isActive: true,
          assignedHostel: 'BH2',
        ),
        StaffMember(
          id: 'rector.bh3@hostel.com',
          name: 'Rector BH3',
          role: 'Rector',
          mobile: '9999999996',
          email: 'rector.bh3@hostel.com',
          isActive: true,
          assignedHostel: 'BH3',
        ),
        StaffMember(
          id: 'rector.bh4@hostel.com',
          name: 'Rector BH4',
          role: 'Rector',
          mobile: '9999999997',
          email: 'rector.bh4@hostel.com',
          isActive: true,
          assignedHostel: 'BH4',
        ),
        StaffMember(
          id: 'rector.gh1@hostel.com',
          name: 'Rector GH1',
          role: 'Rector',
          mobile: '9999999993',
          email: 'rector.gh1@hostel.com',
          isActive: true,
          assignedHostel: 'GH1',
        ),
        StaffMember(
          id: 'rector.gh2@hostel.com',
          name: 'Rector GH2',
          role: 'Rector',
          mobile: '9999999998',
          email: 'rector.gh2@hostel.com',
          isActive: true,
          assignedHostel: 'GH2',
        ),
        StaffMember(
          id: 'warden@hostel.com',
          name: 'Head Warden',
          role: 'Warden',
          mobile: '9999999994',
          email: 'warden@hostel.com',
          isActive: true,
        ),
        StaffMember(
          id: 'guard@hostel.com',
          name: 'Main Gate Guard',
          role: 'Guard',
          mobile: '9999999995',
          email: 'guard@hostel.com',
          isActive: true,
          assignedShift: 'Day',
        ),
      ];

      for (var staff in defaults) {
        // Check if exists to avoid duplicates/overwrites logic if needed,
        // but repository.addStaff typically sets ID.
        // Here we want to force these IDs if possible or just add them.
        // For simplicity, we just use addStaff which uses set(merge:true) if implemented well,
        // or we manually set them here.
        // Looking at standard repository pattern, let's use FireStore direct to ensure specific IDs (for easier cleanup later if needed)

        await FirebaseFirestore.instance
            .collection('staff')
            .doc(staff.email)
            .set(staff.toMap());
        // Using email as doc ID for easiest "upsert" preventing duplicates
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Default Staff Generated! You can now Register them.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Staff Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'seed') {
                _seedDefaultStaff();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'seed',
                  child: Text('Generate Default Staff'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount:
                          1, // Full width boxes as per drawing, or 2 for grid. The drawing suggests 1 vertical list of boxes. We will use a ListView of boxed items for the top level menus to exactly match the whiteboard-style drawing logic.
                      childAspectRatio: 3.5, // Make them rectangular boxes
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildRoleBox(
                          context,
                          'Warden',
                          Icons.admin_panel_settings,
                        ),
                        _buildRoleBox(context, 'HOD', Icons.school),
                        _buildRoleBox(context, 'Rector', Icons.home_work),
                        _buildRoleBox(context, 'Guard', Icons.security),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRoleBox(BuildContext context, String role, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StaffListScreen(role: role, repository: _repository),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF002244)),
            const SizedBox(width: 16),
            Text(
              role.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFF002244),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Screen 2: The List Screen for a specific role --- //
class StaffListScreen extends StatefulWidget {
  final String role;
  final StaffRepository repository;

  const StaffListScreen({
    super.key,
    required this.role,
    required this.repository,
  });

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  // Reuse the Add/Edit Dialog here for the specific role
  void _showAddEditDialog({StaffMember? staff}) {
    final nameController = TextEditingController(text: staff?.name ?? '');
    final mobileController = TextEditingController(text: staff?.mobile ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    String role = staff?.role ?? widget.role; // Default to this screen's role
    String? shift = staff?.assignedShift;
    String? hostel = staff?.assignedHostel;
    String? category = staff?.assignedCategory;
    String? branch = staff?.assignedBranch;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            staff == null ? 'Add New ${widget.role}' : 'Edit ${widget.role}',
          ),
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
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Linked Account)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                ),
                const SizedBox(height: 12),
                if (role.toUpperCase() == 'HOD') ...[
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Degree', 'Diploma']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        category = val;
                        branch = null; // Reset branch when category changes
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: branch,
                    decoration: const InputDecoration(
                      labelText: 'Branch/Department',
                    ),
                    items:
                        (category == 'Degree'
                                ? [
                                    'IT & MSC-IT',
                                    'B.VOC',
                                    'CSE',
                                    'BBA & MBA',
                                    'Chemical',
                                    'Electrical',
                                    'Pharmacy',
                                    'Civil Engineering',
                                  ]
                                : category == 'Diploma'
                                ? [
                                    'Electrical Engineering',
                                    'Chemical Engineering',
                                    'Information Technology',
                                    'Computer Engineering',
                                    'Mechanical Engineering',
                                  ]
                                : <String>[])
                            .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)),
                            )
                            .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        branch = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: shift,
                  decoration: const InputDecoration(labelText: 'Assign Shift'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("None")),
                    const DropdownMenuItem(
                      value: "Day",
                      child: Text("Day (8am-8pm)"),
                    ),
                    const DropdownMenuItem(
                      value: "Night",
                      child: Text("Night (8pm-8am)"),
                    ),
                  ],
                  onChanged: (val) => shift = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: hostel,
                  decoration: const InputDecoration(labelText: 'Assign Hostel'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("None (Global)"),
                    ),
                    const DropdownMenuItem(
                      value: "BH1",
                      child: Text("Boys Hostel 1"),
                    ),
                    const DropdownMenuItem(
                      value: "BH2",
                      child: Text("Boys Hostel 2"),
                    ),
                    const DropdownMenuItem(
                      value: "BH3",
                      child: Text("Boys Hostel 3"),
                    ),
                    const DropdownMenuItem(
                      value: "BH4",
                      child: Text("Boys Hostel 4"),
                    ),
                    const DropdownMenuItem(
                      value: "GH1",
                      child: Text("Girls Hostel 1"),
                    ),
                    const DropdownMenuItem(
                      value: "GH2",
                      child: Text("Girls Hostel 2"),
                    ),
                  ],
                  onChanged: (val) => hostel = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => isLoading = true);

                      try {
                        final newStaff = StaffMember(
                          id:
                              staff?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          role: role,
                          mobile: mobileController.text.trim(),
                          email: emailController.text.trim().toLowerCase(),
                          isActive: true, // Default active
                          assignedShift: shift,
                          assignedHostel: hostel,
                          assignedCategory: category,
                          assignedBranch: branch,
                        );

                        if (staff == null) {
                          await widget.repository.addStaff(newStaff);
                        } else {
                          await widget.repository.updateStaff(newStaff);
                        }

                        // SYNC TO USERS COLLECTION
                        if (newStaff.email != null &&
                            newStaff.email!.isNotEmpty) {
                          try {
                            final userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: newStaff.email)
                                .get();

                            if (userQuery.docs.isNotEmpty) {
                              for (var doc in userQuery.docs) {
                                String userRole = 'student';
                                final lowerRole = newStaff.role.toLowerCase();
                                if (lowerRole.contains('rector')) {
                                  userRole = 'rector';
                                } else if (lowerRole.contains('warden')) {
                                  userRole = 'warden';
                                } else if (lowerRole.contains('mess')) {
                                  userRole = 'mess_manager';
                                } else if (lowerRole.contains('guard')) {
                                  userRole = 'guard';
                                } else if (lowerRole.contains('hod')) {
                                  userRole = 'hod';
                                }

                                await doc.reference.update({
                                  'role': userRole,
                                  'assignedHostel': hostel,
                                  'category': category,
                                  'branch': branch,
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint("Error syncing user: $e");
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Staff saved successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002244),
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(staff == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${widget.role} List',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF002244),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<StaffMember>>(
        stream: widget.repository.getAllStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No staff members found'));
          }

          // Filter by the requested role
          final filteredStaff = snapshot.data!
              .where((s) => s.role.toLowerCase() == widget.role.toLowerCase())
              .toList();

          if (filteredStaff.isEmpty) {
            return Center(child: Text('No ${widget.role} found in database.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredStaff.length,
            itemBuilder: (context, index) {
              final staff = filteredStaff[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFCF5F5,
                  ), // Keeping your exact design color
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${staff.role} • ${staff.assignedShift ?? "No Shift"} • ${staff.assignedHostel ?? "Global"}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _showAddEditDialog(staff: staff),
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
}
