import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../../utils/canonical_names.dart';
import '../../services/push_notification_service.dart';

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

  // Global Broadcast values
  final _broadcastFormKey = GlobalKey<FormState>();
  final _broadcastTitleController = TextEditingController();
  final _broadcastBodyController = TextEditingController();
  String _broadcastTarget = 'all'; // 'all', 'student', 'staff'
  bool _isBroadcasting = false;

  @override
  void dispose() {
    _broadcastTitleController.dispose();
    _broadcastBodyController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        String csvString;

        if (kIsWeb) {
          // On Web, path is unavailable, so we use bytes
          if (result.files.first.bytes != null) {
            csvString = const Utf8Decoder().convert(result.files.first.bytes!);
          } else {
            setState(() => _statusMessage = "Error: File content is empty (No bytes)");
            return;
          }
        } else {
          // On Mobile/Desktop, path is preferred but fallback to bytes if needed
          if (result.files.first.path != null) {
            final file = File(result.files.first.path!);
            csvString = await file.readAsString();
          } else if (result.files.first.bytes != null) {
            csvString = const Utf8Decoder().convert(result.files.first.bytes!);
          } else {
            setState(() => _statusMessage = "Error: Could not read file content (No path or bytes)");
            return;
          }
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

        // Check for Google Forms Export ("Timestamp" column) or leading empty column
        if (csvTable.isNotEmpty && csvTable[0].isNotEmpty) {
          final firstCell = csvTable[0][0].toString().toLowerCase();
          if (firstCell.isEmpty || firstCell.contains('timestamp')) {
            // Remove the first column from EVERY row to shift the data
            for (int i = 0; i < csvTable.length; i++) {
              if (csvTable[i].isNotEmpty) {
                csvTable[i].removeAt(0);
              }
            }
          }
        }

        // Remove Header if present (assuming Row 0 is header)
        if (csvTable.isNotEmpty) {
          // Check if first row looks like a header row
          // Supports both old format (email at col 1) and new format (email at col 5)
          final firstCell = csvTable[0][0].toString().toLowerCase();
          final hasEmailInCol1 = csvTable[0].length > 1 &&
              csvTable[0][1].toString().toLowerCase().contains('email');
          final hasEmailInCol5 = csvTable[0].length > 5 &&
              csvTable[0][5].toString().toLowerCase().contains('email');
          if (firstCell.contains('name') && (hasEmailInCol1 || hasEmailInCol5)) {
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
          // CSV format (14-col new format):
          // Name(0), EnrollmentNo(1), Gender(2), BloodGroup(3),
          // StudentMobile(4), Email(5), FatherMobile(6), MotherMobile(7),
          // Institute(8), Program(9), Department(10), Hostel(11), Floor(12), Room(13)
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
          String program = '';
          String branch = '';
          String hostel = '';
          String floor = '';
          String room = '';
          String category = 'Degree';

          if (isNewFormat) {
            // New 14-column format
            enrollmentNo = AppConfig.formatEnrollmentNo(row.length > 1 ? row[1] : null, fallback: '');
            gender      = row.length > 2 ? row[2].toString().trim() : '';
            bloodGroup  = row.length > 3 ? row[3].toString().trim() : '';
            studentMobile = row.length > 4 ? row[4].toString().trim() : '';
            fatherMobile  = row.length > 6 ? row[6].toString().trim() : '';
            motherMobile  = row.length > 7 ? row[7].toString().trim() : '';
            institute   = row.length > 8 ? row[8].toString().trim() : '';
            program     = row.length > 9 ? row[9].toString().trim() : '';
            branch      = row.length > 10 ? row[10].toString().trim() : '';
            hostel      = row.length > 11 ? row[11].toString().trim() : '';
            floor       = row.length > 12 ? row[12].toString().trim() : '';
            room        = row.length > 13 ? row[13].toString().trim() : '';
            // Map institute name to category
            // Handles both short codes (RNGPIT, NGPP) and full/partial names
            final instituteUpper = institute.toUpperCase();
            if (instituteUpper.contains('RNGPIT') ||
                instituteUpper.contains('R.N.G') ||
                instituteUpper.contains('RNG PATEL') ||
                instituteUpper.contains('R. N. G')) {
              category = 'Degree';
            } else if (instituteUpper.contains('NGPP') ||
                instituteUpper.contains('DIPLOMA')) {
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

          // Canonicalize branch name to match AppConfig lists
          branch = CanonicalNames.canonicalizeBranch(branch, category);

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
            'program': program,
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
          updateData['enrollmentNo'] = AppConfig.formatEnrollmentNo(row.length > 1 ? row[1] : null, fallback: '');
          updateData['gender']       = row.length > 2 ? row[2].toString().trim() : '';
          updateData['bloodGroup']   = row.length > 3 ? row[3].toString().trim() : '';
          updateData['mobile']       = row.length > 4 ? row[4].toString().trim() : '';
          updateData['fatherMobile'] = row.length > 6 ? row[6].toString().trim() : '';
          updateData['motherMobile'] = row.length > 7 ? row[7].toString().trim() : '';
          updateData['parentContact']= row.length > 6 ? row[6].toString().trim() : '';
          updateData['institute']    = inst;
          updateData['category']     = cat;
          updateData['program']      = row.length > 9 ? row[9].toString().trim() : '';
          
          String rawBranch           = row.length > 10 ? row[10].toString().trim() : '';
          updateData['branch']       = CanonicalNames.canonicalizeBranch(rawBranch, cat);
          
          final String hostelName    = row.length > 11 ? row[11].toString().trim() : '';
          updateData['hostel']       = hostelName;
          updateData['assignedHostel'] = _getShortHostelCode(hostelName);
          updateData['floor']        = row.length > 12 ? row[12].toString().trim() : '';
          updateData['room']         = row.length > 13 ? row[13].toString().trim() : '';
        } else {
          // Old 7-column format: Name, Email, Hostel, Room, Branch, Year, Category
          updateData['name'] = row[0].toString().trim();
          
          final String hostelName = row.length > 2 ? row[2].toString().trim() : '';
          updateData['hostel'] = hostelName;
          updateData['assignedHostel'] = _getShortHostelCode(hostelName);
          
          updateData['room'] = row.length > 3 ? row[3].toString().trim() : '';
          
          final String cat = row.length > 6 ? row[6].toString().trim() : 'Degree';
          updateData['category'] = cat;
          
          final String rawBranch = row.length > 4 ? row[4].toString().trim() : '';
          updateData['branch'] = CanonicalNames.canonicalizeBranch(rawBranch, cat);
          
          updateData['year'] = row.length > 5 ? row[5].toString().trim() : '';
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
    // Check if the input is already a short code
    if (AppConfig.hostelCodes.values.contains(fullName)) {
      return fullName;
    }
    // Otherwise, try to find it by full name
    return AppConfig.getHostelCode(fullName);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    "New CSV Format (14 columns):",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Person Name, Enrollment No., Gender, Blood Group, Person Mobile 1, Person Email, Father Mobile No., Mother Mobile No., Institute, Program, Department, Hostel, Floor, Room",
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Institute: Use 'RNGPIT' for Degree, 'NGPP' for Diploma.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
            SizedBox(
              height: 200,
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

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // 📢 GLOBAL BROADCAST PANEL CARD
          _buildSectionHeader('Global Broadcast Panel', Icons.campaign),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _broadcastFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send immediate high-priority push and in-app notifications to users.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Target Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _broadcastTarget,
                      decoration: InputDecoration(
                        labelText: 'Target Audience',
                        prefixIcon: const Icon(Icons.people, color: Color(0xFF002244)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Registered Users')),
                        DropdownMenuItem(value: 'student', child: Text('Students Only')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _broadcastTarget = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title Textfield
                    TextFormField(
                      controller: _broadcastTitleController,
                      decoration: InputDecoration(
                        labelText: 'Broadcast Title',
                        prefixIcon: const Icon(Icons.title, color: Color(0xFF002244)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Message Textfield
                    TextFormField(
                      controller: _broadcastBodyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Broadcast Message',
                        prefixIcon: const Icon(Icons.message, color: Color(0xFF002244)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Message body is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isBroadcasting ? null : _sendBroadcast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48), // Rose 600
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isBroadcasting
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send Broadcast',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF002244), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002244),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    if (!_broadcastFormKey.currentState!.validate()) return;

    setState(() => _isBroadcasting = true);

    final title = _broadcastTitleController.text.trim();
    final message = _broadcastBodyController.text.trim();
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Fetch target users from Firestore
      Query query = firestore.collection('users');

      if (_broadcastTarget == 'student') {
        query = query.where('role', isEqualTo: 'student');
      } else if (_broadcastTarget == 'staff') {
        query = query.where('role', whereIn: ['warden', 'rector', 'hod', 'guard', 'mess_manager', 'admin']);
      }

      final querySnapshot = await query.get();
      final usersDocs = querySnapshot.docs;

      if (usersDocs.isEmpty) {
        throw 'No registered users found matching target group.';
      }

      List<String> targetUids = [];
      List<String> tokens = [];

      for (var doc in usersDocs) {
        final data = doc.data() as Map<String, dynamic>;
        targetUids.add(doc.id);
        final token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      // 2. Batched write to 'notifications' collection for in-app feeds
      final batch = firestore.batch();
      for (final uid in targetUids) {
        final docRef = firestore.collection('notifications').doc();
        batch.set(docRef, {
          'title': title,
          'message': message,
          'receiverUid': uid,
          'type': 'system_broadcast',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // 3. Send Push Notifications via PushNotificationService
      final pushService = PushNotificationService();
      int successCount = 0;
      for (final token in tokens) {
        try {
          await pushService.sendNotification(
            title: title,
            body: message,
            toToken: token,
          );
          successCount++;
        } catch (e) {
          debugPrint('Error sending push to token: $e');
        }
      }

      // Clear fields
      _broadcastTitleController.clear();
      _broadcastBodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Broadcast complete! Logged in-app for ${targetUids.length} users and pushed to $successCount devices.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to broadcast: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isBroadcasting = false);
    }
  }
}
