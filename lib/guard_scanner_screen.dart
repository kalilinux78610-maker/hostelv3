import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});

  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen>
    with WidgetsBindingObserver {
  late MobileScannerController controller;
  bool _isProcessing = false;

  // Session History
  final List<Map<String, String>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  // --- Manual Search UI ---
  void _showManualEntrySheet() {
    final TextEditingController idController = TextEditingController();
    String? selectedWing;
    final List<String> wings = ['A', 'B', 'C', 'D', 'E'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Manual Search",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002244),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select wing and enter enrollment ID",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Wing Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: wings.map((wing) {
                    final isSelected = selectedWing == wing;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text("Wing $wing"),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() {
                            selectedWing = selected ? wing : null;
                          });
                        },
                        selectedColor: const Color(0xFF002244),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF002244)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // ID Input
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  labelText: "Enrollment ID",
                  hintText: "e.g. 210345",
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (idController.text.isNotEmpty) {
                      _searchByEnrollmentId(idController.text.trim());
                    }
                  },
                  child: const Text(
                    "SEARCH STUDENT",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Search Logic ---
  Future<void> _searchByEnrollmentId(String enrollmentId) async {
    setState(() => _isProcessing = true);
    try {
      final possibleEmails = [
        "$enrollmentId@rngpit.com",
        "$enrollmentId@gmail.com",
      ];

      final querySnapshot = await FirebaseFirestore.instance
          .collection('leave_requests')
          .where('email', whereIn: possibleEmails)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          _showResultSheet(
            false,
            "No Active Pass",
            "No approved pass found for ID: $enrollmentId",
          );
        }
      } else {
        _verifyPass(querySnapshot.docs.first.id);
      }
    } catch (e) {
      if (mounted) {
        _showResultSheet(false, "Search Error", e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // --- Verification Logic ---
  Future<void> _verifyPass(String? docId) async {
    if (docId == null) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        _showResultSheet(false, "Invalid Pass", "Document not found.");
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'];
      final endDate = (data['endDate'] as Timestamp).toDate();
      final startDate = (data['startDate'] as Timestamp).toDate();
      final now = DateTime.now();

      final Timestamp? actualOutTime = data['actualOutTime'];
      final Timestamp? actualInTime = data['actualInTime'];

      bool isSameDay =
          now.year == startDate.year &&
          now.month == startDate.month &&
          now.day == startDate.day;

      if (status != 'approved') {
        _showResultSheet(false, "Access Denied", "Pass is NOT Approved.");
      } else if (!isSameDay && now.isBefore(startDate)) {
        _showResultSheet(
          false,
          "Not Yet Active",
          "Pass is valid from ${startDate.toString().split(' ')[0]}",
        );
      } else if (now.isAfter(endDate) && actualInTime != null) {
        _showResultSheet(false, "Expired", "Pass expired.");
      } else {
        // Valid Pass
        String actionButtonText = "CLOSE";
        VoidCallback? onAction;
        String studentEmail = data['email'] ?? 'Unknown';
        String studentId = studentEmail.split('@')[0];
        String reason = data['reason'] ?? 'N/A';
        String message = "ID: $studentId\nReason: $reason";

        if (actualOutTime == null) {
          actionButtonText = "MARK CHECK-OUT";
          onAction = () => _markTime(docId, 'actualOutTime', studentId, "EXIT");
        } else if (actualInTime == null) {
          actionButtonText = "MARK CHECK-IN";
          onAction = () => _markTime(docId, 'actualInTime', studentId, "ENTRY");
        } else {
          message += "\n\nTrip Completed.";
        }

        _showResultSheet(
          true,
          "Access Granted",
          message,
          actionLabel: actionButtonText,
          onAction: onAction,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultSheet(false, "Error", "Failed to verify: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markTime(
    String docId,
    String field,
    String studentId,
    String type,
  ) async {
    Navigator.pop(context); // Close sheet
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .update({field: FieldValue.serverTimestamp()});

      setState(() {
        _recentScans.insert(0, {
          'id': studentId,
          'type': type,
          'time':
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        });
        if (_recentScans.length > 5) _recentScans.removeLast();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$type marked for $studentId"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showResultSheet(
    bool isSuccess,
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (isSuccess) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSuccess ? Colors.green[50] : Colors.red[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green[100] : Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green[800] : Colors.red[800],
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green[900] : Colors.red[900],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess
                      ? Colors.green[700]
                      : Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (onAction != null) {
                    onAction();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  actionLabel ?? "SCAN NEXT",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "CANCEL / SCAN NEXT",
                  style: TextStyle(
                    color: isSuccess ? Colors.green[900] : Colors.red[900],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F5,
      ), // Light background for dashboard style
      appBar: AppBar(
        title: const Text(
          "Guard Console",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Scanner Frame
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          if (!_isProcessing) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              _verifyPass(barcode.rawValue);
                              break;
                            }
                          }
                        },
                      ),
                      // Scanner Overlay Graphic
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // Loading Indicator
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Place QR code within frame",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 30),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _showManualEntrySheet,
                      icon: const Icon(Icons.keyboard),
                      label: const Text(
                        "MANUAL SEARCH",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => controller.toggleTorch(),
                        icon: const Icon(Icons.flash_on),
                        tooltip: "Toggle Flash",
                      ),
                      const SizedBox(width: 20),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => controller.switchCamera(),
                        icon: const Icon(Icons.cameraswitch),
                        tooltip: "Switch Camera",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Recent Activity Section
            if (_recentScans.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002244),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentScans.length,
                      separatorBuilder: (c, i) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final scan = _recentScans[index];
                        final isExit = scan['type'] == 'EXIT';
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isExit
                                    ? Colors.red[50]
                                    : Colors.green[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isExit ? Icons.logout : Icons.login,
                                size: 16,
                                color: isExit ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scan['id']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  scan['type']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isExit ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              scan['time']!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
