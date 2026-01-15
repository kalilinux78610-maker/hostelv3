import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomAvailabilityScreen extends StatefulWidget {
  const RoomAvailabilityScreen({super.key});

  @override
  State<RoomAvailabilityScreen> createState() => _RoomAvailabilityScreenState();
}

class _RoomAvailabilityScreenState extends State<RoomAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _hostels = [
    'Boys Hostel 1',
    'Boys Hostel 2',
    'Boys Hostel 3',
    'Boys Hostel 4',
    'Girls Hostel 1',
    'Girls Hostel 2',
  ];

  Map<String, Map<String, List<Map<String, dynamic>>>> _roomData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _hostels.length, vsync: this);
    _fetchRoomData();
  }

  Future<void> _fetchRoomData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('student_imports')
          .get();

      // Structure: Hostel -> Room -> List of Students
      final Map<String, Map<String, List<Map<String, dynamic>>>> data = {};

      for (var hostel in _hostels) {
        data[hostel] = {};
      }

      for (var doc in snapshot.docs) {
        final student = doc.data();
        final hostel = student['hostel'] as String? ?? 'Unknown';
        final room = student['room'] as String? ?? 'Unknown';

        // Normalize hostel name logic if needed (Assuming exact match for now)
        // If your DB uses short codes like BH1, we'd need a mapper.
        // Assuming 'hostel' field stores full name "Boys Hostel 1" based on bulk import logic.

        String? matchedHostel;
        for (var h in _hostels) {
          // Flexible matching
          if (hostel.toLowerCase().contains(h.toLowerCase()) ||
              (h.contains('Boys Hostel 1') && hostel == 'BH1')) {
            matchedHostel = h;
            break;
          }
        }

        if (matchedHostel != null) {
          if (!data[matchedHostel]!.containsKey(room)) {
            data[matchedHostel]![room] = [];
          }
          data[matchedHostel]![room]!.add(student);
        }
      }

      setState(() {
        _roomData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching room data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Visualizer"),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: _hostels.map((h) => Tab(text: h)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _hostels.map((hostel) {
                return _buildHostelGrid(hostel);
              }).toList(),
            ),
    );
  }

  Widget _buildHostelGrid(String hostelName) {
    final rooms = _roomData[hostelName] ?? {};
    if (rooms.isEmpty) {
      return const Center(child: Text("No data found for this hostel"));
    }

    // Sort rooms logic (numeric comparison)
    final sortedRooms = rooms.keys.toList()
      ..sort((a, b) {
        int? rA = int.tryParse(a);
        int? rB = int.tryParse(b);
        if (rA != null && rB != null) return rA.compareTo(rB);
        return a.compareTo(b);
      });

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 rooms per row
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final roomNum = sortedRooms[index];
        final students = rooms[roomNum]!;
        final count = students.length;
        final capacity = 3; // Should ideally be dynamic, but 3 is standard

        Color color;
        if (count == 0) {
          color = Colors.green; // Empty (Shouldn't happen if keyed by data)
        } else if (count < capacity) {
          color = Colors.orange; // Partial
        } else {
          color = Colors.red; // Full or Overloaded
        }

        return InkWell(
          onTap: () => _showRoomDetails(context, roomNum, students),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  roomNum,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$count/$capacity",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Icon(Icons.bed, size: 16, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRoomDetails(
    BuildContext context,
    String room,
    List<Map<String, dynamic>> students,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Room $room Details",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Room appears empty in records."),
                )
              else
                ...students.map(
                  (s) => ListTile(
                    leading: CircleAvatar(
                      child: Text((s['name'] ?? 'U')[0].toUpperCase()),
                    ),
                    title: Text(s['name'] ?? 'Unknown Name'),
                    subtitle: Text(s['email'] ?? 'No Email'),
                    dense: true,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
