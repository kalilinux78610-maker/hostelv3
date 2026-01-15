import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../admin/tabs/mess_management_screen.dart';

class MessManagerDashboard extends StatefulWidget {
  const MessManagerDashboard({super.key});

  @override
  State<MessManagerDashboard> createState() => _MessManagerDashboardState();
}

class _MessManagerDashboardState extends State<MessManagerDashboard> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF002244);

  static const List<Widget> _widgetOptions = <Widget>[
    MessManagementScreen(),
    Center(child: Text("Purchase & Stock (Coming Soon)")),
    Center(child: Text("Profile Settings")),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      FirebaseAuth.instance.signOut();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Manager'),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu & Feedback',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
