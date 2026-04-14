import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  static const Color _primaryColor = Color(0xFF002244);
  
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    // Determine today's tab index index
    final todayStr = _getTodayDayString();
    int initialIndex = _days.indexOf(todayStr);
    if (initialIndex == -1) initialIndex = 0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('mess_menu').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
             appBar: AppBar(title: const Text('Mess Menu'), backgroundColor: _primaryColor),
             body: Center(child: Text("Error loading menu: ${snapshot.error}")),
          );
        }

        final docData = snapshot.data?.data() as Map<String, dynamic>?;
        final menuData = docData ?? {};

        return DefaultTabController(
          length: _days.length,
          initialIndex: initialIndex,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: const Text(
                "Weekly Mess Menu",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: _primaryColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: Colors.orange,
                indicatorWeight: 4,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.white70,
                tabs: _days.map((day) {
                  return Tab(text: day == todayStr ? "$day (Today)" : day);
                }).toList(),
              ),
            ),
            body: TabBarView(
              children: _days.map((day) {
                return _buildMenuForDay(day, menuData);
              }).toList(),
            ),
          ),
        );
      }
    );
  }

  String _getTodayDayString() {
    int weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return 'Monday';
    }
  }

  Widget _buildMenuForDay(String day, Map<String, dynamic>? data) {
    bool hasData = false;
    Map<String, String> items = {};
    if (data != null && data.containsKey(day)) {
      items = (data[day] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()));
      for (var val in items.values) {
        if (val.trim().isNotEmpty && val.trim() != "N/A") {
          hasData = true;
          break;
        }
      }
    }

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Menu for $day is not set yet.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }


    // Extract image URLs from the raw data map
    final rawDay = (data != null && data.containsKey(day)) ? data[day] as Map<String, dynamic> : {};
    final breakfastImg = rawDay['Breakfast_imageUrl'] as String?;
    final lunchImg = rawDay['Lunch_imageUrl'] as String?;
    final dinnerImg = rawDay['Dinner_imageUrl'] as String?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMealCard(
          title: "Breakfast",
          icon: Icons.free_breakfast,
          time: "07:30 AM - 09:00 AM",
          items: items['Breakfast']?.isNotEmpty == true ? items['Breakfast']! : "Not available",
          color: Colors.orange,
          imageUrl: breakfastImg,
        ),
        _buildMealCard(
          title: "Lunch",
          icon: Icons.lunch_dining,
          time: "12:30 PM - 02:00 PM",
          items: items['Lunch']?.isNotEmpty == true ? items['Lunch']! : "Not available",
          color: Colors.green,
          imageUrl: lunchImg,
        ),
        _buildMealCard(
          title: "Dinner",
          icon: Icons.dinner_dining,
          time: "07:30 PM - 09:00 PM",
          items: items['Dinner']?.isNotEmpty == true ? items['Dinner']! : "Not available",
          color: _primaryColor,
          imageUrl: dinnerImg,
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String title,
    required IconData icon,
    required String time,
    required String items,
    required Color color,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: color.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  const Spacer(),
                  Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                ],
              ),
            ),
            // Meal Photo
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            // Items text
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                items,
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
