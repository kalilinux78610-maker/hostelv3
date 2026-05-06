import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'repositories/notification_repository.dart';

class NotificationScreen extends StatefulWidget {
  final String userRole;

  const NotificationScreen({super.key, required this.userRole});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _repository = NotificationRepository();
  final _currentUser = FirebaseAuth.instance.currentUser;

  static const Color _primaryColor = Color(0xFF002244);
  static const Color _orange = Color(0xFFFF6B00);

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns icon, background color, and icon color for a notification
  _NotifStyle _styleFor(String title, String type) {
    final t = title.toLowerCase();
    if (t.contains('approved') || t.contains('✅')) {
      return _NotifStyle(
        icon: Icons.check,
        bgColor: const Color(0xFF1A7A5E),
        iconColor: Colors.white,
        tag: _tag('LEAVE REQUEST APPROVED', const Color(0xFFD0F5EA), const Color(0xFF1A7A5E)),
      );
    } else if (t.contains('rejected') || t.contains('❌') || t.contains('reject')) {
      return _NotifStyle(
        icon: Icons.close,
        bgColor: Colors.grey[600]!,
        iconColor: Colors.white,
        tag: _tag('REQUEST REJECTED', const Color(0xFFFFE5E5), Colors.red),
      );
    } else if (t.contains('submitted') || t.contains('new') || t.contains('logged')) {
      return _NotifStyle(
        icon: Icons.article_outlined,
        bgColor: _primaryColor,
        iconColor: Colors.white,
        tag: _tag('NEW REQUEST SUBMITTED', const Color(0xFFE5EEFF), const Color(0xFF3B5BDB)),
      );
    } else if (t.contains('mess') || t.contains('menu')) {
      return _NotifStyle(
        icon: Icons.restaurant,
        bgColor: Colors.grey[500]!,
        iconColor: Colors.white,
        tag: _tag('MESS MENU UPDATED FOR THIS WEEK', const Color(0xFFFFEEDD), _orange),
      );
    } else {
      return _NotifStyle(
        icon: Icons.notifications_outlined,
        bgColor: Colors.grey[400]!,
        iconColor: Colors.white,
        tag: _tag('NOTIFICATION', const Color(0xFFF0F0F0), Colors.grey),
      );
    }
  }

  Widget _tag(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final now = DateTime.now();
    final date = ts.toDate();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  /// Groups notifications by date section: TODAY, YESTERDAY, EARLIER
  Map<String, List<QueryDocumentSnapshot>> _groupByDate(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> groups = {
      'TODAY': [],
      'YESTERDAY': [],
      'EARLIER': [],
    };
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) {
        groups['TODAY']!.add(doc);
        continue;
      }
      final date = ts.toDate();
      final docDay = DateTime(date.year, date.month, date.day);
      if (docDay == today) {
        groups['TODAY']!.add(doc);
      } else if (docDay == yesterday) {
        groups['YESTERDAY']!.add(doc);
      } else {
        groups['EARLIER']!.add(doc);
      }
    }
    return groups;
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _repository.getNotifications(
          uid: _currentUser.uid,
          role: widget.userRole,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Notification Stream Error: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading notifications: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState();
          }

          // Sort newest first
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          final groups = _groupByDate(docs);

          return ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              if (groups['TODAY']!.isNotEmpty) ...[
                _sectionHeader('TODAY'),
                ...groups['TODAY']!.map((d) => _notificationCard(d)),
              ],
              if (groups['YESTERDAY']!.isNotEmpty) ...[
                _sectionHeader('YESTERDAY'),
                ...groups['YESTERDAY']!.map((d) => _notificationCard(d)),
              ],
              if (groups['EARLIER']!.isNotEmpty) ...[
                _sectionHeader('EARLIER'),
                ...groups['EARLIER']!.map((d) => _notificationCard(d)),
              ],
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Mark all as read
            final user = _currentUser;
            if (user == null) return;
            final snap = await FirebaseFirestore.instance
                .collection('notifications')
                .where('receiverUid', isEqualTo: user.uid)
                .where('isRead', isEqualTo: false)
                .get();
            for (final doc in snap.docs) {
              doc.reference.update({'isRead': true});
            }
          },
          child: const Text(
            'Mark all read',
            style: TextStyle(
              color: _orange,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _notificationCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isRead = data['isRead'] ?? false;
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final type = data['type'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final style = _styleFor(title, type);

    return GestureDetector(
      onTap: () {
        if (!isRead) _repository.markAsRead(doc.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isRead ? Colors.transparent : _orange,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: style.bgColor,
                child: Icon(style.icon, color: style.iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14.5,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel(ts),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Message
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tag chip
                    style.tag,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 36,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Style Helper ────────────────────────────────────────────────────────────────
class _NotifStyle {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final Widget tag;

  const _NotifStyle({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.tag,
  });
}
