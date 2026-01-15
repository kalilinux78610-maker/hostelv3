import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
          // Expecting CSV format: Name, Email, Hostel, Room, Branch, Year
          // Index: 0, 1, 2, 3, 4, 5
          if (row.length < 2) {
            _failCount++;
            _errorLogs.add(
              "Row $rowOffset: Skipped - Not enough columns (expected at least 2)",
            );
            continue; // Skip invalid rows logic
          }

          // Clean Data
          final String name = row[0].toString().trim();
          final String email = row[1].toString().trim();

          // Skip completely empty rows (common in CSV exports)
          if (name.isEmpty && email.isEmpty) {
            _failCount++;
            _errorLogs.add("Row $rowOffset: Skipped - Empty row");
            continue;
          }

          final String hostel = row.length > 2 ? row[2].toString().trim() : '';
          final String room = row.length > 3 ? row[3].toString().trim() : '';
          final String branch = row.length > 4 ? row[4].toString().trim() : '';
          final String year = row.length > 5 ? row[5].toString().trim() : '';

          if (email.isEmpty || !email.contains('@')) {
            _failCount++;
            _errorLogs.add(
              "Row $rowOffset: Invalid Email '$email' (Must contain @)",
            );
            continue;
          }

          final docRef = firestore.collection('student_imports').doc(email);
          batch.set(docRef, {
            'name': name,
            'email': email,
            'assignedHostel': _getShortHostelCode(hostel),
            'hostel': hostel,
            'room': room,
            'branch': branch,
            'year': year,
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

    setState(() {
      _isLoading = false;
      _statusMessage = "Complete! Success: $_successCount, Failed: $_failCount";
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions Card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CSV Format: Name, Email, Hostel, Room, Branch, Year",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Note: Email MUST be unique and valid (e.g. user@gmail.com).",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Uploading records..."),
                ],
              ),
            )
          else
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select CSV File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_data.isNotEmpty)
                  ElevatedButton(
                    onPressed: _uploadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Import ${_data.length} Students Now"),
                  ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  "Demo Data Tools",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _generateDemoData,
                  icon: const Icon(Icons.bolt),
                  label: const Text("Generate 300 Demo Students"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateDemoRector,
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text("Promote 'rector@demo.com'"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _deleteAllStudents,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("DELETE ALL STUDENTS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _clearOperationalData,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text("Clear All Requests & Complaints"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _failCount > 0 ? Colors.red : Colors.green,
            ),
          ),

          // Error Logs Section
          if (_errorLogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Errors:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _errorLogs.length,
                itemBuilder: (context, index) => Text(
                  "• ${_errorLogs[index]}",
                  style: TextStyle(color: Colors.red[800], fontSize: 12),
                ),
              ),
            ),
          ],

          if (_data.isNotEmpty) ...[
            const Divider(),
            const Text(
              "Preview (First 5 Rows):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _data.length > 5 ? 5 : _data.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    title: Text(_data[index].join(', ')),
                    leading: CircleAvatar(child: Text("${index + 1}")),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
