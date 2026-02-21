import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});

  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Camera
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processScannedData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Corner Lines
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _cornerLine(true, true)),
                  Positioned(top: 0, right: 0, child: _cornerLine(true, false)),
                  Positioned(bottom: 0, left: 0, child: _cornerLine(false, true)),
                  Positioned(bottom: 0, right: 0, child: _cornerLine(false, false)),
                ],
              ),
            ),
          ),

          // 4. Animated Scan Line
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, _animationController.value * 2 - 1),
                    child: Container(
                      height: 2,
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 5. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 6. Instruction Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: const Text(
              "Align QR Code within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),

          // 7. Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cornerLine(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.green, width: 4)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft:
              (isTop && isLeft) ? const Radius.circular(10) : Radius.zero,
          topRight:
              (isTop && !isLeft) ? const Radius.circular(10) : Radius.zero,
          bottomLeft:
              (!isTop && isLeft) ? const Radius.circular(10) : Radius.zero,
          bottomRight:
              (!isTop && !isLeft) ? const Radius.circular(10) : Radius.zero,
        ),
      ),
    );
  }

  Future<void> _processScannedData(String scannedValue) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('enrollment', isEqualTo: scannedValue.trim())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showErrorAndResume("Student not found: $scannedValue");
        return;
      }

      final userDoc = userQuery.docs.first;
      final studentName = userDoc['name'] ?? 'Unknown';
      final uid = userDoc.id;

      final passQuery = await FirebaseFirestore.instance
          .collection('leave_requests')
          .where('userId', isEqualTo: uid)
          .where('status', whereIn: ['approved', 'out'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (passQuery.docs.isEmpty) {
        _showErrorAndResume("No active pass for $studentName");
        return;
      }

      final passDoc = passQuery.docs.first;
      final passData = passDoc.data();
      final status = passData['status'];
      final docId = passDoc.id;

      if (mounted) {
        await _showVerificationDialog(docId, passData, studentName, status);
      }
    } catch (e) {
      _showErrorAndResume("Error: $e");
    }
  }

  void _showErrorAndResume(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _showVerificationDialog(
      String docId, Map<String, dynamic> data, String name, String status) async {
    bool isCheckOut = status == 'approved';
    Color color = isCheckOut ? Colors.orange : Colors.green;
    String actionLabel = isCheckOut ? "MARK CHECK-OUT" : "MARK CHECK-IN";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCheckOut ? "Verify Check-Out?" : "Verify Check-In?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Student: $name",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text("Reason: ${data['reason'] ?? 'N/A'}"),
            Text("Destination: ${data['destination'] ?? 'N/A'}"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Row(
                children: [
                  Icon(isCheckOut ? Icons.exit_to_app : Icons.login,
                      color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCheckOut
                          ? "Status: APPROVED (Not Out)"
                          : "Status: CURRENTLY OUT",
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await _updatePassStatus(docId, isCheckOut);
              if (mounted) navigator.pop();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassStatus(String docId, bool isCheckOut) async {
    try {
      if (isCheckOut) {
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(docId)
            .update({
          'status': 'out',
          'actualOutTime': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(docId)
            .update({
          'status': 'completed',
          'actualInTime': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isCheckOut
                ? "Checked OUT Successfully"
                : "Checked IN Successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
