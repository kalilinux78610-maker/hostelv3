import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/staff_model.dart';
import '../../repositories/staff_repository.dart';
import '../../app_config.dart';
import '../../utils/canonical_names.dart';

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
          id: 'rector.ngp@hostel.com',
          name: 'Rector NGP',
          role: 'Rector',
          mobile: '9999999991',
          email: 'rector.ngp@hostel.com',
          isActive: true,
          assignedHostel: 'NGP',
        ),
        StaffMember(
          id: 'rector.ngpp@hostel.com',
          name: 'Rector NGPP',
          role: 'Rector',
          mobile: '9999999992',
          email: 'rector.ngpp@hostel.com',
          isActive: true,
          assignedHostel: 'NGPP',
        ),
        StaffMember(
          id: 'rector.nvbh@hostel.com',
          name: 'Rector NVBH',
          role: 'Rector',
          mobile: '9999999996',
          email: 'rector.nvbh@hostel.com',
          isActive: true,
          assignedHostel: 'NVBH',
        ),
        StaffMember(
          id: 'rector.wbh@hostel.com',
          name: 'Rector WBH',
          role: 'Rector',
          mobile: '9999999997',
          email: 'rector.wbh@hostel.com',
          isActive: true,
          assignedHostel: 'WBH',
        ),
        StaffMember(
          id: 'rector.sh@hostel.com',
          name: 'Rector SH',
          role: 'Rector',
          mobile: '9999999993',
          email: 'rector.sh@hostel.com',
          isActive: true,
          assignedHostel: 'SH',
        ),
        StaffMember(
          id: 'rector.pjmf@hostel.com',
          name: 'Rector PJMF',
          role: 'Rector',
          mobile: '9999999998',
          email: 'rector.pjmf@hostel.com',
          isActive: true,
          assignedHostel: 'PJMF',
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
  List<String> _getAvailableBranches(String? category) {
    final branches = [
      ...(category == null
          ? <String>[]
          : AppConfig.getBranchesForCategory(category)),
    ];
    if (category == 'Degree' && !branches.contains('Mechanical Engineering')) {
      branches.add('Mechanical Engineering');
    }
    return branches;
  }

  // Reuse the Add/Edit Dialog here for the specific role
  void _showAddEditDialog({StaffMember? staff}) {
    final nameController = TextEditingController(text: staff?.name ?? '');
    final mobileController = TextEditingController(text: staff?.mobile ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    String role = staff?.role ?? widget.role; // Default to this screen's role
    String? shift = staff?.assignedShift;
    String? category = staff?.assignedCategory;
    List<String> assignedBranches = staff?.assignedBranches?.toList() ?? [];
    if (assignedBranches.isEmpty && staff?.assignedBranch != null) {
      assignedBranches.add(staff!.assignedBranch!);
    }
    List<String> assignedHostels = staff?.assignedHostels?.toList() ?? [];
    if (assignedHostels.isEmpty && staff?.assignedHostel != null) {
      assignedHostels.add(staff!.assignedHostel!);
    }
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
                if (role.toUpperCase() == 'HOD' || role.toUpperCase() == 'WARDEN') ...[
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Degree', 'Diploma']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        category = val;
                        assignedBranches = []; // Reset branches when category changes
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Branch/Department (Multiple)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _getAvailableBranches(category).map((String b) {
                      return FilterChip(
                        label: Text(b),
                        selected: assignedBranches.contains(b),
                        selectedColor: const Color(0xFF002244).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF002244),
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              assignedBranches.add(b);
                            } else {
                              assignedBranches.remove(b);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (role.toUpperCase() != 'HOD') ...[
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
                ],
                const Text('Assign Hostels', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: AppConfig.hostelCodes.values.map((String h) {
                    return FilterChip(
                      label: Text(AppConfig.getFullHostelName(h)),
                      selected: assignedHostels.contains(h),
                      selectedColor: const Color(0xFF002244).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF002244),
                      onSelected: (bool selected) {
                        setDialogState(() {
                          if (selected) {
                            assignedHostels.add(h);
                          } else {
                            assignedHostels.remove(h);
                          }
                        });
                      },
                    );
                  }).toList(),
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
                        final canonicalBranches = assignedBranches
                            .map((b) => CanonicalNames.canonicalizeBranch(b, category))
                            .toSet()
                            .toList();
                        final canonicalBranch =
                            canonicalBranches.isNotEmpty ? canonicalBranches.first : null;
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
                          assignedHostel: assignedHostels.isNotEmpty ? assignedHostels.first : null,
                          assignedHostels: assignedHostels,
                          assignedCategory: category,
                          assignedBranch: canonicalBranch,
                          assignedBranches: canonicalBranches,
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
                                  'assignedHostel': assignedHostels.isNotEmpty ? assignedHostels.first : null,
                                  'assignedHostels': assignedHostels,
                                  'category': category,
                                  'assignedCategory': category,
                                  'branch': canonicalBranch,
                                  'assignedBranch': canonicalBranch,
                                  'branches': canonicalBranches,
                                  'assignedBranches': canonicalBranches,
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
                            '${staff.role} • ${staff.assignedShift ?? "No Shift"} • ${staff.assignedHostels?.isNotEmpty == true ? staff.assignedHostels!.join(", ") : (staff.assignedHostel ?? "Global")}',
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
