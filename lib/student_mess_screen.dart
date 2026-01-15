import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/mess_model.dart';
import '../../repositories/mess_repository.dart';

class StudentMessScreen extends StatefulWidget {
  const StudentMessScreen({super.key});

  @override
  State<StudentMessScreen> createState() => _StudentMessScreenState();
}

class _StudentMessScreenState extends State<StudentMessScreen> {
  final _repository = MessRepository();
  final DateTime _today = DateTime.now();
  int _rating = 0;
  final _commentController = TextEditingController();

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final feedback = MessFeedback(
      id: '',
      studentId: user.uid,
      studentName: user.email?.split('@')[0] ?? 'Student',
      date: DateTime.now(),
      mealType: _getMealTypeByTime(),
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    await _repository.submitFeedback(feedback);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Feedback submitted!')));
      setState(() {
        _rating = 0;
        _commentController.clear();
      });
    }
  }

  String _getMealTypeByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 16) return 'Lunch';
    return 'Dinner';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Menu'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Today's Menu Card
            StreamBuilder<MessMenu?>(
              stream: _repository.getMenuForDate(_today),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final menu = snapshot.data;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          "Today's Menu (${_today.day}/${_today.month})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (menu == null)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Menu not updated yet."),
                          )
                        else ...[
                          _buildMenuRow(
                            "Breakfast",
                            menu.breakfast,
                            Icons.breakfast_dining,
                          ),
                          const SizedBox(height: 12),
                          _buildMenuRow(
                            "Lunch",
                            menu.lunch,
                            Icons.lunch_dining,
                          ),
                          const SizedBox(height: 12),
                          _buildMenuRow(
                            "Dinner",
                            menu.dinner,
                            Icons.dinner_dining,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Feedback Section
            const Text(
              "Rate Your Last Meal",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Current Meal: ${_getMealTypeByTime()}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.orange,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Review (e.g. Too salty, great chicken)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002244),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Submit Feedback"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(String title, List<String> items, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF002244)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                items.isEmpty ? "Not set" : items.join(', '),
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
