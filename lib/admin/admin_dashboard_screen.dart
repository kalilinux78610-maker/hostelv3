import 'package:flutter/material.dart';
import 'tabs/activity_feed_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/student_directory_screen.dart';
import 'tabs/staff_management_screen.dart';
import 'tabs/bulk_import_screen.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF002244);

  static final List<Widget> _widgetOptions = <Widget>[
    ActivityFeedTab(),
    StudentDirectoryScreen(),
    StaffManagementScreen(),
    ReportsTab(),
    BulkImportScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2 || _selectedIndex == 4)
          ? null
          : AppBar(
              title: const Text('Admin Dashboard'),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => _buildLogoutDialog(ctx),
                    );
                    if (shouldLogout == true) await AuthService.signOut();
                  },
                ),
              ],
            ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed, // Added for >3 items
          items: <BottomNavigationBarItem>[
            _buildNavItem(Icons.rss_feed, 'Activity', 0),
            _buildNavItem(Icons.people, 'Directory', 1),
            _buildNavItem(Icons.badge, 'Staff', 2),
            _buildNavItem(Icons.bar_chart, 'Reports', 3),
            _buildNavItem(Icons.upload_file, 'Import', 4),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1E3A8A), // Match design dark blue
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          onTap: _onItemTapped,
          elevation: 0,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 4),
            )
          else
            const SizedBox(height: 7),
          Icon(icon),
        ],
      ),
      label: label,
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
