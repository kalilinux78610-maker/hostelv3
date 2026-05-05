import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/common_providers.dart';
import '../../domain/entities/complaint.dart';
import '../providers/complaint_provider.dart';
import 'file_complaint_screen.dart';

// ─── Design tokens (consistent with FileComplaintScreen) ──────────────────────
const _kNavy = Color(0xFF0A1628);
const _kAccent = Color(0xFFD4AF37);
const _kSurface = Color(0xFFF7F9FC);
const _kBorder = Color(0xFFE2E8F0);

class StudentComplaintsScreen extends ConsumerStatefulWidget {
  const StudentComplaintsScreen({super.key});

  @override
  ConsumerState<StudentComplaintsScreen> createState() =>
      _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends ConsumerState<StudentComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kAccent.withAlpha(46),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.headset_mic_rounded,
                  color: _kAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Complaints',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: _kNavy,
            child: TabBar(
              controller: _tabController,
              indicatorColor: _kAccent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'New Complaint'),
                Tab(text: 'My Complaints'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const FileComplaintScreen(),
          const _ComplaintsList(),
        ],
      ),
    );
  }

}

class _ComplaintsList extends ConsumerWidget {
  const _ComplaintsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    if (user == null) {
      return const Center(child: Text('Please login to view complaints'));
    }

    final complaintsAsync = ref.watch(studentComplaintsProvider(user.uid));

    return complaintsAsync.when(
      data: (complaints) {
        if (complaints.isEmpty) return _EmptyState();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: complaints.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _ComplaintCard(complaint: complaints[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: _kNavy)),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _kNavy.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 42, color: _kNavy),
          ),
          const SizedBox(height: 16),
          const Text(
            'No complaints yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your filed complaints will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintEntity complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint.status;
    final statusInfo = _statusInfo(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kNavy.withAlpha(10),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kNavy.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_categoryIcon(complaint.category),
                          size: 13, color: _kNavy),
                      const SizedBox(width: 5),
                      Text(
                        complaint.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusInfo.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusInfo.fg,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusInfo.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y • h:mm a')
                          .format(complaint.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                if (complaint.adminComment != null &&
                    complaint.adminComment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 13,
                                color: Color(0xFF1D4ED8)),
                            SizedBox(width: 5),
                            Text(
                              'Admin Response',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          complaint.adminComment!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color fg}) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
      case 'in progress':
        return (bg: const Color(0xFFFEF9C3), fg: const Color(0xFFCA8A04));
      default:
        return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFDC2626));
    }
  }

  IconData _categoryIcon(String category) {
    if (category.contains('Light')) return Icons.lightbulb_outline;
    if (category.contains('Fan')) return Icons.air;
    if (category.contains('Circuit')) return Icons.electrical_services;
    if (category.contains('Bathroom')) return Icons.bathroom_outlined;
    if (category.contains('Water')) return Icons.water_drop_outlined;
    if (category.contains('Mess') || category.contains('Food')) {
      return Icons.restaurant_menu;
    }
    if (category.contains('Furniture')) return Icons.chair_outlined;
    if (category.contains('Internet') || category.contains('Wi-Fi')) {
      return Icons.wifi_off_rounded;
    }
    return Icons.help_outline_rounded;
  }
}
