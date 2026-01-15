import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/staff_model.dart';
import '../../repositories/staff_repository.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _repository = StaffRepository();
  bool _isLoading = false;

  void _showAddEditDialog({StaffMember? staff}) {
    final nameController = TextEditingController(text: staff?.name ?? '');
    final mobileController = TextEditingController(text: staff?.mobile ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    String role = staff?.role ?? 'Guard';
    String? shift = staff?.assignedShift;
    String? hostel = staff?.assignedHostel;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(staff == null ? 'Add New Staff' : 'Edit Staff'),
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
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items:
                    [
                          'Rector',
                          'Warden',
                          'Guard',
                          'Cleaner',
                          'Cook',
                          'Mess Manager',
                        ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (val) => role = val!,
              ),
              const SizedBox(height: 12),
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
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);

              try {
                final newStaff = StaffMember(
                  id:
                      staff?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  role: role,
                  mobile: mobileController.text.trim(),
                  email: emailController.text.trim(),
                  isActive: true, // Default active
                  assignedShift: shift,
                  assignedHostel: hostel,
                );

                if (staff == null) {
                  await _repository.addStaff(newStaff);
                } else {
                  await _repository.updateStaff(newStaff);
                }

                // SYNC TO USERS COLLECTION
                if (newStaff.email != null && newStaff.email!.isNotEmpty) {
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
                        }

                        await doc.reference.update({
                          'role': userRole,
                          'assignedHostel': hostel,
                        });
                      }
                    }
                  } catch (e) {
                    debugPrint("Error syncing user: $e");
                  }
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff saved successfully')),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002244),
              foregroundColor: Colors.white,
            ),
            child: Text(staff == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

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
      appBar: AppBar(
        title: const Text('Staff Management'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF002244),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<StaffMember>>(
              stream: _repository.getAllStaff(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No staff members found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final staff = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Icon(Icons.person, color: Colors.blue[800]),
                        ),
                        title: Text(
                          staff.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${staff.role} • ${staff.assignedShift ?? "No Shift"} • ${staff.assignedHostel ?? "Global"}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _showAddEditDialog(staff: staff),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
