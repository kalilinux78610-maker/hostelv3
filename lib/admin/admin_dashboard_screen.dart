import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tabs/activity_feed_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/student_directory_screen.dart';
import 'tabs/staff_management_screen.dart';

import 'tabs/bulk_import_screen.dart';

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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Added for >3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'Activity',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Directory'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Import',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
