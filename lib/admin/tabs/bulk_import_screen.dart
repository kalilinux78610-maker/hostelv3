import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  bool _isLoading = false;
  String _statusMessage = "";
  List<List<dynamic>> _data = [];
  int _successCount = 0;
  int _failCount = 0;
  List<String> _errorLogs = []; // State for error logs

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        String csvString;

        // Use path on mobile/desktop (more reliable than bytes in some cases)
        if (result.files.first.path != null) {
          final file = File(result.files.first.path!);
          csvString = await file.readAsString();
        } else if (result.files.first.bytes != null) {
          // Fallback for Web or if path is null
          csvString = const Utf8Decoder().convert(result.files.first.bytes!);
        } else {
          setState(
            () => _statusMessage =
                "Error: Could not read file content (No path or bytes)",
          );
          return;
        }

        // Normalize Newlines (Handle \r\n, \r, and \n)
        csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        // Parse CSV
        // eol: '\n' might be needed if auto-detection fails, but usually it works.
        // We set shouldParseNumbers: false to keep phone/room as strings
        List<List<dynamic>> csvTable = const CsvToListConverter(
          shouldParseNumbers: false,
          eol: '\n', // Explicitly set EOL now that we normalized it
        ).convert(csvString);

        int originalCount = csvTable.length;

        // Remove Header if present (assuming Row 0 is header)
        if (csvTable.isNotEmpty) {
          // Check if first row looks like header
          final firstCell = csvTable[0][0].toString().toLowerCase();
          if (firstCell.contains('name') &&
              (csvTable[0].length > 1 &&
                  csvTable[0][1].toString().toLowerCase().contains('email'))) {
            csvTable.removeAt(0);
          }
        }

        setState(() {
          _data = csvTable;
          _statusMessage =
              "File Loaded. Found: $originalCount rows. Records to Import: ${_data.length}";
          if (_data.isEmpty) {
            _statusMessage +=
                "\n(Warning: File appeared empty or only header found)";
          }
        });
      }
    } catch (e) {
      setState(() => _statusMessage = "Error picking file: $e");
    }
  }

  Future<void> _uploadData() async {
    if (_data.isEmpty) return;

    setState(() {
      _isLoading = true;
      _successCount = 0;
      _failCount = 0;
      _errorLogs = []; // Clear previous errors
    });

    final firestore = FirebaseFirestore.instance;
    final batchSize = 400; // Firestore batch limit is 500

    // Process in batches
    for (var i = 0; i < _data.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize < _data.length) ? i + batchSize : _data.length;
      final chunk = _data.sublist(i, end);

      int rowOffset = i;

      for (var row in chunk) {
        rowOffset++;
        try {
          // CSV format: Name(0), EnrollmentNo(1), Gender(2), BloodGroup(3),
          // StudentMobile(4), Email(5), FatherMobile(6), MotherMobile(7),
          // Institute(8), Department(9), Hostel(10), Floor(11), Room(12)
          if (row.length < 2) {
            _failCount++;
            _errorLogs.add(
              "Row $rowOffset: Skipped - Not enough columns (expected at least 2)",
            );
            continue;
          }

          // Clean Data
          final String name = row[0].toString().trim();

          // Support both old format (email at col 1) and new format (email at col 5)
          final bool isNewFormat = row.length >= 6 && row[5].toString().contains('@');
          final String email = isNewFormat
              ? row[5].toString().trim().toLowerCase()
              : row[1].toString().trim().toLowerCase();

          // Skip completely empty rows
          if (name.isEmpty && email.isEmpty) {
            _failCount++;
            _errorLogs.add("Row $rowOffset: Skipped - Empty row");
            continue;
          }

          if (email.isEmpty || !email.contains('@')) {
            _failCount++;
            _errorLogs.add(
              "Row $rowOffset: Invalid Email '$email' (Must contain @)",
            );
            continue;
          }

          String enrollmentNo = '';
          String gender = '';
          String bloodGroup = '';
          String studentMobile = '';
          String fatherMobile = '';
          String motherMobile = '';
          String institute = '';
          String branch = '';
          String hostel = '';
          String floor = '';
          String room = '';
          String category = 'Degree';

          if (isNewFormat) {
            // New 13-column format
            enrollmentNo = row.length > 1 ? row[1].toString().trim() : '';
            gender      = row.length > 2 ? row[2].toString().trim() : '';
            bloodGroup  = row.length > 3 ? row[3].toString().trim() : '';
            studentMobile = row.length > 4 ? row[4].toString().trim() : '';
            fatherMobile  = row.length > 6 ? row[6].toString().trim() : '';
            motherMobile  = row.length > 7 ? row[7].toString().trim() : '';
            institute   = row.length > 8 ? row[8].toString().trim() : '';
            branch      = row.length > 9 ? row[9].toString().trim() : '';
            hostel      = row.length > 10 ? row[10].toString().trim() : '';
            floor       = row.length > 11 ? row[11].toString().trim() : '';
            room        = row.length > 12 ? row[12].toString().trim() : '';
            // Map institute name to category
            if (institute.toUpperCase() == 'RNGPIT') {
              category = 'Degree';
            } else if (institute.toUpperCase() == 'NGPP') {
              category = 'Diploma';
            } else {
              category = institute.isNotEmpty ? institute : 'Degree';
            }
          } else {
            // Old 7-column format: Name, Email, Hostel, Room, Branch, Year, Category
            hostel   = row.length > 2 ? row[2].toString().trim() : '';
            room     = row.length > 3 ? row[3].toString().trim() : '';
            branch   = row.length > 4 ? row[4].toString().trim() : '';
            category = row.length > 6 ? row[6].toString().trim() : 'Degree';
          }

          final docRef = firestore.collection('student_imports').doc(email);
          batch.set(docRef, {
            'name': name,
            'email': email,
            'enrollmentNo': enrollmentNo,
            'gender': gender,
            'bloodGroup': bloodGroup,
            'mobile': studentMobile,
            'fatherMobile': fatherMobile,
            'motherMobile': motherMobile,
            'institute': institute,
            'assignedHostel': _getShortHostelCode(hostel),
            'hostel': hostel,
            'floor': floor,
            'room': room,
            'branch': branch,
            'category': category,
            'importedAt': FieldValue.serverTimestamp(),
          });
          _successCount++;
        } catch (e) {
          _failCount++;
          _errorLogs.add("Row $rowOffset: Error - $e");
          debugPrint("Error row: $row -> $e");
        }
      }

      await batch.commit();
      setState(() {
        _statusMessage = "Importing... Processed $end / ${_data.length}";
      });
    }

    // SECOND PASS: Directly update already-registered students in 'users' collection
    setState(() => _statusMessage = "Syncing profiles of already-registered students...");
    int syncCount = 0;
    for (var row in _data) {
      try {
        final bool isNewFormat = row.length >= 6 && row[5].toString().contains('@');
        final String email = isNewFormat
            ? row[5].toString().trim().toLowerCase()
            : row[1].toString().trim().toLowerCase();
        if (email.isEmpty || !email.contains('@')) continue;

        // Build the same field map as we saved to student_imports
        final Map<String, dynamic> updateData = {};
        if (isNewFormat) {
          final String inst = row.length > 8 ? row[8].toString().trim() : '';
          String cat = 'Degree';
          if (inst.toUpperCase() == 'RNGPIT') {
            cat = 'Degree';
          } else if (inst.toUpperCase() == 'NGPP') {
            cat = 'Diploma';
          } else if (inst.isNotEmpty) {
            cat = inst;
          }

          updateData['name']         = row[0].toString().trim();
          updateData['enrollmentNo'] = row.length > 1 ? row[1].toString().trim() : '';
          updateData['gender']       = row.length > 2 ? row[2].toString().trim() : '';
          updateData['bloodGroup']   = row.length > 3 ? row[3].toString().trim() : '';
          updateData['mobile']       = row.length > 4 ? row[4].toString().trim() : '';
          updateData['fatherMobile'] = row.length > 6 ? row[6].toString().trim() : '';
          updateData['motherMobile'] = row.length > 7 ? row[7].toString().trim() : '';
          updateData['parentContact']= row.length > 6 ? row[6].toString().trim() : '';
          updateData['institute']    = inst;
          updateData['category']     = cat;
          updateData['branch']       = row.length > 9 ? row[9].toString().trim() : '';
          final String hostelName    = row.length > 10 ? row[10].toString().trim() : '';
          updateData['hostel']       = hostelName;
          updateData['assignedHostel'] = _getShortHostelCode(hostelName);
          updateData['floor']        = row.length > 11 ? row[11].toString().trim() : '';
          updateData['room']         = row.length > 12 ? row[12].toString().trim() : '';
        }

        if (updateData.isEmpty) continue;

        // Find user by email in 'users' collection
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          await userQuery.docs.first.reference.update(updateData);
          syncCount++;
        }
      } catch (e) {
        debugPrint("Sync error for row: $e");
      }
    }

    setState(() {
      _isLoading = false;
      _statusMessage = "Complete! Imported: $_successCount, Synced existing: $syncCount, Failed: $_failCount";
      _data = []; // Clear after upload
    });
  }

  Future<void> _generateDemoData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Generating 300 demo records...";
      _successCount = 0;
      _failCount = 0;
      _errorLogs = [];
    });

    final firestore = FirebaseFirestore.instance;
    // Single batch for 300 items is fine (limit is 500)
    final batch = firestore.batch();

    // Config: 4 Boys Hostels, 2 Girls Hostels
    final boysHostels = [
      'Boys Hostel 1',
      'Boys Hostel 2',
      'Boys Hostel 3',
      'Boys Hostel 4',
    ];
    final girlsHostels = ['Girls Hostel 1', 'Girls Hostel 2'];
    final branches = ['CS', 'IT', 'Mech', 'Civil', 'Elec'];
    final years = ['1', '2', '3', '4'];

    // Simple random generator helper
    int random(int max) => DateTime.now().microsecondsSinceEpoch % max;
    T randomItem<T>(List<T> list) => list[random(list.length)];

    for (int i = 0; i < 300; i++) {
      try {
        final isBoy = random(2) == 0;
        final firstName = isBoy
            ? [
                'Aarav',
                'Vihaan',
                'Aditya',
                'Sai',
                'Rohan',
                'Karan',
                'Arjun',
                'Rahul',
                'Vikram',
                'Amit',
              ][random(10)]
            : [
                'Diya',
                'Saanvi',
                'Ananya',
                'Priya',
                'Neha',
                'Ishita',
                'Kavya',
                'Riya',
                'Sneha',
                'Pooja',
              ][random(10)];
        final lastName = [
          'Sharma',
          'Patel',
          'Singh',
          'Verma',
          'Gupta',
          'Kumar',
          'Reddy',
          'Das',
          'Joshi',
          'Mehta',
        ][random(10)];

        final name = "$firstName $lastName";
        final email =
            "${firstName.toLowerCase()}.${lastName.toLowerCase()}${random(9999)}@demo.com";

        final hostel = isBoy
            ? randomItem(boysHostels)
            : randomItem(girlsHostels);
        final assignedHostel = _getShortHostelCode(hostel);
        final room = "${1 + random(3)}${10 + random(89)}"; // e.g. 110, 245, 399
        final branch = randomItem(branches);
        final year = randomItem(years);

        final docRef = firestore.collection('student_imports').doc(email);
        batch.set(docRef, {
          'name': name,
          'email': email,
          'assignedHostel': assignedHostel,
          'hostel': hostel,
          'room': room,
          'branch': branch,
          'year': year,
          'importedAt': FieldValue.serverTimestamp(),
          'source': 'demo_data_generator',
        });
        _successCount++;

        // Small delay to ensure better random seed usage if needed,
        // though microsecond modulo is usually fine.
        await Future.delayed(const Duration(microseconds: 100));
      } catch (e) {
        _failCount++;
        debugPrint("Error generating demo user: $e");
      }
    }

    await batch.commit();

    setState(() {
      _isLoading = false;
      _statusMessage = "Generated $_successCount demo students!";
    });
  }

  Future<void> _generateDemoRector() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Creating demo rector account...";
    });

    try {
      // 1. Create in Firestore directly (User must 'Sign Up' with this email to set password,
      // OR we just create a record so if they sign up it works?
      // Actually, authentication is separate.
      // QUICK FIX: We'll add a user record. The Admin must use 'Create User' or similar.
      // BUT, to make this easy for testing without Auth implementation details:
      // We will add to 'student_imports' with role 'rector' effectively?
      // No, 'student_imports' is for students.

      // Let's create a valid user document. The User still needs to Authenticate.
      // Since I can't create an Auth user without their password,
      // I will assume the user registers as "rector@demo.com" and we manually upgrade them here
      // OR I instruct the user to register.

      // BETTER: Just output the instruction.
      // "Please Register a new user with email 'rector@demo.com', then click this button again to promote them."

      // WAIT: I can check if 'rector@demo.com' exists in Users.
      // If not, I can pre-create the user doc so when they sign up (if logic allows)
      // OR just tell them "Register with this email".

      // Let's Try: Create a 'staff_imports' or just set it in Users if they exist.
      // Assuming the user (YOU) wants to test, I will update YOUR current user to Rector temporarily?
      // No, that's dangerous.

      // Plan:
      // 1. Check if 'rector@demo.com' exists in `users`.
      // 2. If yes, update role = 'rector', assignedHostel = 'BH1'.
      // 3. If no, create a placeholder doc so "RoleChecker" might find it if they sign up?
      //    AuthWrapper checks Firestore AFTER Auth. So they must Auth first.

      // AUTO-PROMOTION STRATEGY:
      // I will create a doc in `users` with email `rector@demo.com`.
      // NOTE: Use a real UID if possible, but we don't know it.
      // Filter: We can't query by email easily in all rules.

      // OK, safer bet:
      // Just print credentials to use: "rector@demo.com" / "password123".
      // AND a button to "Promote rector@demo.com" which searches for that email in users.

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: 'rector@demo.com')
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'role': 'rector',
          'assignedHostel': 'BH1', // Default to Boys Hostel 1
        });
        setState(
          () => _statusMessage =
              "Success! 'rector@demo.com' is now a Rector (BH1).",
        );
      } else {
        // If user doesn't exist in Firestore yet (maybe not registered),
        // we can't easily bridge Auth UID.
        // Instructions are better.
        setState(
          () => _statusMessage =
              "User 'rector@demo.com' not found. \n1. Sign Up as 'rector@demo.com'. \n2. Click this button again.",
        );
      }
    } catch (e) {
      debugPrint("Error promoting rector: $e");
      setState(() => _statusMessage = "Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("DANGER: Delete ALL Students?"),
        content: const Text(
          "This will permanently delete:\n\n1. ALL Pre-registered Students (Allocation List)\n2. ALL Active Student Accounts\n\nThis action cannot be undone. Are you absolutely sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red[50],
            ),
            child: const Text("DELETE EVERYTHING"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "Deleting all student records...";
    });

    final firestore = FirebaseFirestore.instance;
    int deletedCount = 0;

    try {
      // 1. Delete from student_imports
      var importsQuery = await firestore.collection('student_imports').get();
      while (importsQuery.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (var doc in importsQuery.docs) {
          batch.delete(doc.reference);
          deletedCount++;
        }
        await batch.commit();

        // Fetch next batch if any (though usually get() returns all,
        // strictly for massive datasets we might paginate, but standard get is likely fine for <20k docs here)
        // To be safe against memory issues or limits, we re-fetch effectively if we were paginating,
        // but here let's assume one fetch covers it or handle rudimentary looping if needed.
        // Actually, for delete, best practice is to query limit.
        // But for simplicity in this demo wrapper:
        if (importsQuery.docs.length > 500) {
          // If we had a limit, we would re-query.
          // Since we did .get() without limit, we have all of them in memory.
          // Batching committed the deletes. We are done with this collection.
          break;
        } else {
          break;
        }
      }

      // 2. Delete Users where role = student
      var usersQuery = await firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Batch deletes for users
      // Note: splitting large list into chunks of 500
      final userDocs = usersQuery.docs;
      for (var i = 0; i < userDocs.length; i += 500) {
        final batch = firestore.batch();
        final end = (i + 500 < userDocs.length) ? i + 500 : userDocs.length;
        final chunk = userDocs.sublist(i, end);
        for (var doc in chunk) {
          batch.delete(doc.reference);
          deletedCount++;
        }
        await batch.commit();
      }

      setState(() {
        _statusMessage = "Validation Complete. Deleted $deletedCount records.";
        _data = []; // Clear current preview if any
      });
    } catch (e) {
      setState(() => _statusMessage = "Error deleting: $e");
      debugPrint("Delete Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearOperationalData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Requests & Complaints?"),
        content: const Text(
          "This will permanently delete:\n\n1. ALL Leave Requests (Pending, Approved, History)\n2. ALL Complaints\n\nActive students and staff will NOT be affected.\nAre you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear Data"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "Clearing operational data...";
    });

    final firestore = FirebaseFirestore.instance;
    int deletedCount = 0;

    try {
      // 1. Delete Leave Requests
      var leaves = await firestore.collection('leave_requests').get();
      while (leaves.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (var doc in leaves.docs) {
          batch.delete(doc.reference);
          deletedCount++;
        }
        await batch.commit();
        if (leaves.docs.length > 500) break; // Simple safety break
        break;
      }

      // 2. Delete Complaints
      var complaints = await firestore.collection('complaints').get();
      while (complaints.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (var doc in complaints.docs) {
          batch.delete(doc.reference);
          deletedCount++;
        }
        await batch.commit();
        if (complaints.docs.length > 500) break;
        break;
      }

      setState(() {
        _statusMessage = "Cleaned! Removed $deletedCount items.";
      });
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "Error clearing data: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _getShortHostelCode(String fullName) {
    if (fullName.contains('Boys Hostel 1') || fullName == 'BH1') return 'BH1';
    if (fullName.contains('Boys Hostel 2') || fullName == 'BH2') return 'BH2';
    if (fullName.contains('Boys Hostel 3') || fullName == 'BH3') return 'BH3';
    if (fullName.contains('Boys Hostel 4') || fullName == 'BH4') return 'BH4';
    if (fullName.contains('Girls Hostel 1') || fullName == 'GH1') return 'GH1';
    if (fullName.contains('Girls Hostel 2') || fullName == 'GH2') return 'GH2';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormatCard(),
                  const SizedBox(height: 20),
                  _buildUploadSection(),
                  const SizedBox(height: 24),
                  const Text("Demo Data Tools", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1E3A))),
                  const SizedBox(height: 12),
                  _buildDemoToolCard("Generate 300 Demo Students", "Create 300 random demo student records", Icons.bolt, Colors.orange, _generateDemoData),
                  const SizedBox(height: 12),
                  _buildDemoToolCard("Promote 'rector@demo.com'", "Make rector@demo.com as rector (demo)", Icons.campaign, Colors.blue, _generateDemoRector),
                  const SizedBox(height: 12),
                  _buildDemoToolCard("Delete All Students", "Permanently delete all student records", Icons.delete, Colors.red, _deleteAllStudents),
                  const SizedBox(height: 12),
                  _buildDemoToolCard("Clear All Requests & Complaints", "Remove all requests and complaints from the system", Icons.cleaning_services, Colors.purple, _clearOperationalData),
                  const SizedBox(height: 24),
                  if (_statusMessage.isNotEmpty)
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _failCount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  if (_errorLogs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text("Errors:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _errorLogs.length,
                        itemBuilder: (context, index) => Text("• ${_errorLogs[index]}", style: TextStyle(color: Colors.red[800], fontSize: 12)),
                      ),
                    ),
                  ],
                  if (_data.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("Preview (First 5 Rows):", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), color: Colors.white),
                      child: ListView.builder(
                        itemCount: _data.length > 5 ? 5 : _data.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(_data[index].join(', '), style: const TextStyle(fontSize: 12)),
                            leading: CircleAvatar(radius: 12, child: Text("${index + 1}", style: const TextStyle(fontSize: 10))),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
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
            right: -20,
            bottom: -30,
            child: Icon(Icons.cloud_upload, size: 140, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 6),
                    const Text('Import Students', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Import student data using CSV', style: TextStyle(color: Colors.blue[100], fontSize: 13)),
                  ],
                ),
              ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.note_add, color: Colors.blue[600], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("New CSV Format (13 columns)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D1E3A))),
                    const SizedBox(height: 4),
                    Text("Name, Enrollment No, Gender, Blood Group, Student Mobile, Email, Father Mobile, Mother Mobile, Institute, Department, Hostel, Floor, Room", style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text("Institute: Use 'RNGPIT' for Degree, 'NGPP' for Diploma.", style: TextStyle(fontSize: 12, color: Colors.blue[800]))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text("Note: Email MUST be unique and valid (e.g. user@gmail.com).", style: TextStyle(fontSize: 12, color: Colors.red[800]))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload, size: 48, color: Colors.blue[400]),
          const SizedBox(height: 12),
          const Text("Select CSV File", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1E3A))),
          const SizedBox(height: 4),
          Text("Click to browse or drag & drop your CSV file here", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text("Choose CSV File"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1E3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Text("Only CSV files are supported. Max file size: 10MB", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          if (_data.isNotEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text("Import ${_data.length} Students Now"),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoToolCard(String title, String subtitle, IconData icon, MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color[600], shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color[800])),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color[800]),
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
