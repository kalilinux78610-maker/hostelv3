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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late MobileScannerController controller;
  bool _isProcessing = false;
  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
      returnImage: false,
    );
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        _scanAnimationController.repeat(reverse: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        _scanAnimationController.stop();
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  // --- Manual Search UI ---
  void _showManualEntrySheet() {
    final TextEditingController idController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002244).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_alt_outlined,
                    color: Color(0xFF002244),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Manual Search",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002244),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the student's enrollment ID to verify pass.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            // ID Input
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
              decoration: InputDecoration(
                labelText: "Enrollment ID",
                hintText: "210...",
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF002244),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002244),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF002244).withValues(alpha: 0.4),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (idController.text.isNotEmpty) {
                    _searchByEnrollmentId(idController.text.trim());
                  }
                },
                child: const Text(
                  "VERIFY STUDENT",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
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
    HapticFeedback.lightImpact();

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
        // Capitalize Reason
        if (reason.isNotEmpty) {
          reason = reason[0].toUpperCase() + reason.substring(1);
        }

        bool isExit = false;

        if (actualOutTime == null) {
          actionButtonText = "MARK CHECK-OUT";
          isExit = true;
          onAction = () => _markTime(docId, 'actualOutTime', studentId, "EXIT");
        } else if (actualInTime == null) {
          actionButtonText = "MARK CHECK-IN";
          isExit = false;
          onAction = () => _markTime(docId, 'actualInTime', studentId, "ENTRY");
        } else {
          // Trip Completed
          _showResultSheet(
            true,
            "Trip Completed",
            "Student has already returned.",
            studentId: studentId,
            reason: reason,
          );
          return;
        }

        _showResultSheet(
          true,
          isExit ? "Authorized Exit" : "Welcome Back",
          isExit
              ? "Student is authorized to leave."
              : "Student returned on time.",
          actionLabel: actionButtonText,
          onAction: onAction,
          studentId: studentId,
          reason: reason,
          isVerification: true,
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
      final batch = FirebaseFirestore.instance.batch();
      final requestRef = FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId);
      final historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('scan_history')
          .doc();

      batch.update(requestRef, {
        field: FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(historyRef, {
        'studentId': studentId,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  "$type marked for $studentId",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    String? studentId,
    String? reason,
    bool isVerification = false,
  }) {
    if (isSuccess) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    final Color statusColor = isSuccess
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final Color bgColor = isSuccess
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Indicator
            Container(
              height: 6,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),

            // Icon & Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(
                isSuccess ? Icons.verified_user : Icons.gpp_bad,
                color: statusColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Student Details Card (if verified)
            if (isVerification && studentId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.badge, "ID", studentId),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.notes, "Reason", reason ?? "N/A"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "CANCEL",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF002244),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Guard Console",
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- Scanner Section ---
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: controller,
                          onDetect: (capture) {
                            if (!_isProcessing) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _verifyPass(barcode.rawValue);
                                  break;
                                }
                              }
                            }
                          },
                        ),
                        // Custom Overlay with Animation
                        AnimatedBuilder(
                          animation: _scanAnimationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: ScannerOverlayPainter(
                                scanValue: _scanAnimationController.value,
                                color: const Color(0xFF64B5F6),
                              ),
                              child: Container(),
                            );
                          },
                        ),
                        // Loading Blocker
                        if (_isProcessing)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        // Flash Control
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => controller.toggleTorch(),
                            icon: const Icon(Icons.flash_on),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Actions & History ---
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002244),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _showManualEntrySheet,
                          icon: const Icon(Icons.dialpad),
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
                      const SizedBox(height: 24),
                      const Text(
                        "Recent Activity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002244),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('scan_history')
                              .orderBy('timestamp', descending: true)
                              .limit(20)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No recent scans",
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: docs.length,
                              separatorBuilder: (c, i) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final isExit = data['type'] == 'EXIT';
                                final studentId =
                                    data['studentId'] ?? 'Unknown';
                                final timestamp =
                                    data['timestamp'] as Timestamp?;
                                final timeString = timestamp != null
                                    ? "${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                                    : "--:--";

                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isExit
                                            ? Colors.red[50]
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isExit
                                              ? Colors.red.shade100
                                              : Colors.green.shade100,
                                        ),
                                      ),
                                      child: Text(
                                        isExit ? "OUT" : "IN",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isExit
                                              ? Colors.red[700]
                                              : Colors.green[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentId,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF002244),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeString,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Scanner Overlay
class ScannerOverlayPainter extends CustomPainter {
  final double scanValue;
  final Color color;

  ScannerOverlayPainter({required this.scanValue, required this.color})
    : super(
        repaint: Listenable.merge([]),
      ); // In a real app, pass the animation controller as listenable

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double scanAreaSize = width * 0.7; // 70% of scanner width
    final double x = (width - scanAreaSize) / 2;
    final double y = (height - scanAreaSize) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();

    // Top Left
    path.moveTo(x, y + 20);
    path.lineTo(x, y);
    path.lineTo(x + 20, y);

    // Top Right
    path.moveTo(x + scanAreaSize - 20, y);
    path.lineTo(x + scanAreaSize, y);
    path.lineTo(x + scanAreaSize, y + 20);

    // Bottom Right
    path.moveTo(x + scanAreaSize, y + scanAreaSize - 20);
    path.lineTo(x + scanAreaSize, y + scanAreaSize);
    path.lineTo(x + scanAreaSize - 20, y + scanAreaSize);

    // Bottom Left
    path.moveTo(x + 20, y + scanAreaSize);
    path.lineTo(x, y + scanAreaSize);
    path.lineTo(x, y + scanAreaSize - 20);

    canvas.drawPath(path, paint);

    // Scan Line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final double scanLineY = y + (scanAreaSize * scanValue);

    // Draw a gradient or simple line
    // Creating a fading tail effect
    final Rect rect = Rect.fromLTWH(x, scanLineY, scanAreaSize, 4);
    canvas.drawRect(rect, linePaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return scanValue != oldDelegate.scanValue;
  }
}
