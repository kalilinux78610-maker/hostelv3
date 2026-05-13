import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kSurface = Color(0xFFF7F9FC);
const _kBorder = Color(0xFFE2E8F0);

class GuardVerifyScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String studentName;
  final String status; // 'approved' or 'out'

  const GuardVerifyScreen({
    super.key,
    required this.docId,
    required this.data,
    required this.studentName,
    required this.status,
  });

  @override
  State<GuardVerifyScreen> createState() => _GuardVerifyScreenState();
}

class _GuardVerifyScreenState extends State<GuardVerifyScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool get _isCheckOut => widget.status == 'approved';
  DateTime? get _expectedReturnAt =>
      (widget.data['endDate'] as Timestamp?)?.toDate();

  bool get _isLateReturn {
    if (_isCheckOut) return false;
    final expected = _expectedReturnAt;
    if (expected == null) return false;
    return DateTime.now().isAfter(expected);
  }

  int get _lateByMinutes {
    if (!_isLateReturn) return 0;
    final expected = _expectedReturnAt!;
    final diff = DateTime.now().difference(expected);
    return diff.inMinutes < 0 ? 0 : diff.inMinutes;
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Status metadata ──────────────────────────────────────────────────────
  Color get _statusColor => _isCheckOut
      ? const Color(0xFF22C55E)   // green → Approved, Not Out
      : const Color(0xFFF97316);  // orange → Currently Out

  IconData get _statusIcon =>
      _isCheckOut ? Icons.verified_user_rounded : Icons.directions_walk_rounded;

  String get _statusLabel =>
      _isCheckOut ? 'APPROVED (Not Out)' : 'CURRENTLY OUT';

  String get _actionLabel =>
      _isCheckOut ? 'Mark Check-Out' : 'Mark Check-In';

  IconData get _actionIcon =>
      _isCheckOut ? Icons.logout_rounded : Icons.login_rounded;

  // ─── Confirm action ────────────────────────────────────────────────────────
  Future<void> _confirmAction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isCheckOut ? 'Confirm Check-Out?' : 'Confirm Check-In?',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: _kNavy, fontSize: 17),
        ),
        content: Text(
          _isCheckOut
              ? 'Mark ${widget.studentName} as checked OUT of the hostel?'
              : 'Mark ${widget.studentName} as checked IN to the hostel?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckOut
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      if (_isCheckOut) {
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(widget.docId)
            .update({
          'status': 'out',
          'actualOutTime': FieldValue.serverTimestamp(),
        });
      } else {
        final expected = _expectedReturnAt;
        final now = DateTime.now();
        final isLate = expected != null && now.isAfter(expected);
        final lateByMinutes =
            (isLate && expected != null) ? now.difference(expected).inMinutes : 0;

        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(widget.docId)
            .update({
          'status': 'completed',
          'actualInTime': FieldValue.serverTimestamp(),
          'returnStatus': isLate ? 'late' : 'on_time',
          'lateByMinutes': isLate ? lateByMinutes : 0,
        });
      }

      if (mounted) {
        _showSuccessAndPop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF22C55E), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                _isCheckOut ? 'Checked Out!' : 'Checked In!',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kNavy),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.studentName} has been successfully ${_isCheckOut ? 'checked out' : 'checked in'}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);   // close dialog
                    Navigator.pop(context); // back to scanner
                  },
                  child: const Text('Done — Scan Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final reason = data['reason'] ?? 'N/A';
    final leaveType = data['type'] ?? data['leaveType'] ?? 'Outing';
    final hostel = data['assignedHostel'] ?? data['hostelId'] ?? '';
    final room = data['room'] ?? data['roomNumber'] ?? '';
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final photoUrl = data['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Checkout',
          style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold),
        ),

      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ── Security status badge ───────────────────────────────
            _SecurityStatusBadge(
              color: _statusColor,
              icon: _statusIcon,
              label: _statusLabel,
              isCheckOut: _isCheckOut,
              pulseAnim: _pulseAnim,
            ),

            if (_isLateReturn)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_gmailerrorred_rounded,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lateByMinutes > 0
                            ? 'LATE RETURN • ${_lateByMinutes} min late'
                            : 'LATE RETURN',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Student card ────────────────────────────────────────
            _StudentCard(
              name: widget.studentName,
              hostel: hostel,
              room: room,
              photoUrl: photoUrl,
            ),

            // ── Details card ────────────────────────────────────────
            _DetailsCard(
              reason: reason,
              leaveType: leaveType,
              endDate: endDate,
              pulseAnim: _pulseAnim,
            ),
          ],
        ),
      ),

      // ── Bottom action bar ─────────────────────────────────────────────
      bottomNavigationBar: _BottomBar(
        isLoading: _isLoading,
        isCheckOut: _isCheckOut,
        actionLabel: _actionLabel,
        actionIcon: _actionIcon,
        statusColor: _statusColor,
        onCancel: () => Navigator.pop(context),
        onAction: _confirmAction,
      ),
    );
  }
}

// ─── Security Status Badge ─────────────────────────────────────────────────────
class _SecurityStatusBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool isCheckOut;
  final Animation<double> pulseAnim;

  const _SecurityStatusBadge({
    required this.color,
    required this.icon,
    required this.label,
    required this.isCheckOut,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shield icon with pulsing ring
        Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: pulseAnim,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'SECURITY STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Student Card ──────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final String name;
  final String hostel;
  final String room;
  final String? photoUrl;

  const _StudentCard({
    required this.name,
    required this.hostel,
    required this.room,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo / Avatar
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _kNavy.withValues(alpha: 0.08),
              border: Border.all(color: _kBorder, width: 1.5),
              image: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Icon(Icons.person_rounded,
                    size: 40, color: _kNavy.withValues(alpha: 0.4))
                : null,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Name',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Hostel + Room tags
                Wrap(
                  spacing: 8,
                  children: [
                    if (hostel.isNotEmpty)
                      _Tag(label: hostel.toUpperCase()),
                    if (room.isNotEmpty)
                      _Tag(label: 'ROOM $room'.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kNavy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _kNavy,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Details Card ───────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final String reason;
  final String leaveType;
  final DateTime? endDate;
  final Animation<double> pulseAnim;

  const _DetailsCard({
    required this.reason,
    required this.leaveType,
    required this.endDate,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final returnStr = endDate != null
        ? DateFormat('MMM d, hh:mm a').format(endDate!)
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reason
          _DetailRow(
            icon: Icons.work_outline_rounded,
            label: 'REASON',
            title: reason,
            subtitle: leaveType,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _kBorder),
          ),

          // Leave Type
          _DetailRow(
            icon: Icons.category_rounded,
            label: 'LEAVE TYPE',
            title: leaveType,
            subtitle: null,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _kBorder),
          ),

          // Expected return
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_rounded,
                    size: 18, color: _kNavy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPECTED RETURN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      returnStr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                  ],
                ),
              ),
              // Pulsing red dot (live indicator)
              FadeTransition(
                opacity: pulseAnim,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _kNavy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _kNavy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Action Bar ─────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool isLoading;
  final bool isCheckOut;
  final String actionLabel;
  final IconData actionIcon;
  final Color statusColor;
  final VoidCallback onCancel;
  final VoidCallback onAction;

  const _BottomBar({
    required this.isLoading,
    required this.isCheckOut,
    required this.actionLabel,
    required this.actionIcon,
    required this.statusColor,
    required this.onCancel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kNavy,
                side: const BorderSide(color: _kBorder, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Mark Check-Out / Check-In
          Expanded(
            flex: 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : LinearGradient(
                        colors: isCheckOut
                            ? [
                                const Color(0xFF16A34A),
                                const Color(0xFF22C55E)
                              ]
                            : [
                                const Color(0xFFEA580C),
                                const Color(0xFFF97316)
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: isLoading ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onAction,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(actionIcon, size: 18),
                label: Text(
                  isLoading ? 'Processing…' : actionLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
