import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/staff_model.dart';
import '../../repositories/staff_repository.dart';
import '../../services/auth_service.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildRoleCard(context, 'Warden', 'View and manage warden\ndetails and permissions', Icons.shield, Colors.blue),
                      const SizedBox(height: 16),
                      _buildRoleCard(context, 'HOD', 'View and manage HOD\ndetails and permissions', Icons.school, Colors.green),
                      const SizedBox(height: 16),
                      _buildRoleCard(context, 'Rector', 'View and manage rector\ndetails and permissions', Icons.account_balance, Colors.orange),
                      const SizedBox(height: 16),
                      _buildRoleCard(context, 'Guard', 'View and manage guard\ndetails and permissions', Icons.badge, Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1E3A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            bottom: -50,
            child: Icon(Icons.group, size: 160, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Dashboard', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Staff Management', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Manage and view staff members', style: GoogleFonts.inter(color: Colors.blue[100], fontSize: 13)),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 20),
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
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'seed') _seedDefaultStaff();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'seed',
                          child: Text('Generate Default Staff', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, String subtitle, IconData icon, MaterialColor color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffListScreen(role: title, repository: _repository),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color[50],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color[700]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: color[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
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
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'Logging Out?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to\nlog out of your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Log Out',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
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
    String? category = staff?.assignedCategory;
    String? branch = staff?.assignedBranch;
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
                const Text('Assign Hostels', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ['BH1', 'BH2', 'BH3', 'BH4', 'GH1', 'GH2'].map((String h) {
                    return FilterChip(
                      label: Text(h),
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
                                  'assignedHostel': assignedHostels.isNotEmpty ? assignedHostels.first : null,
                                  'assignedHostels': assignedHostels,
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
