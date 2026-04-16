import 'package:flutter/material.dart';
import '../mess_menu_editor_screen.dart';
import '../services/auth_service.dart';
import 'mess_profile_screen.dart';

class MessManagerDashboard extends StatefulWidget {
  const MessManagerDashboard({super.key});

  @override
  State<MessManagerDashboard> createState() => _MessManagerDashboardState();
}

class _MessManagerDashboardState extends State<MessManagerDashboard> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF002244);

  static const List<Widget> _widgetOptions = <Widget>[
    MessMenuEditorScreen(),
    Center(child: Text("Purchase & Stock (Coming Soon)")),
    MessProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      AuthService.signOut();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
