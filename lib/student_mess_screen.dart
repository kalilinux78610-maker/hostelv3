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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF002244),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'MESS MENU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF002244), Color(0xFF003870)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimingsSection(),
                  const SizedBox(height: 24),
                  _buildTodayMenuSection(),
                  const SizedBox(height: 32),
                  _buildFeedbackSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MESS TIMINGS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  "B: 8-10 AM • L: 1-3 PM • D: 8-10 PM",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMenuSection() {
    return StreamBuilder<MessMenu?>(
      stream: _repository.getMenuForDate(_today),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final menu = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TODAY'S SPECIAL",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "${_today.day}/${_today.month}",
                  style: const TextStyle(
                    color: Color(0xFF002244),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (menu == null)
              _buildEmptyMenuCard()
            else ...[
              _buildModernMenuCard(
                "Breakfast",
                menu.breakfast,
                "08:00 AM",
                Icons.wb_sunny_outlined,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),
              _buildModernMenuCard(
                "Lunch",
                menu.lunch,
                "01:00 PM",
                Icons.sunny,
                const Color(0xFFFFC107),
              ),
              const SizedBox(height: 16),
              _buildModernMenuCard(
                "Dinner",
                menu.dinner,
                "08:00 PM",
                Icons.nightlight_round,
                const Color(0xFF673AB7),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyMenuCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Menu not updated yet",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuCard(
    String title,
    List<String> items,
    String time,
    IconData icon,
    Color color,
  ) {
    bool isCurrentMeal = _getMealTypeByTime() == title;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isCurrentMeal
            ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: color),
                          const SizedBox(width: 8),
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        items.isEmpty ? "Menu not set" : items.join(' • '),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002244),
                        ),
                      ),
                      if (isCurrentMeal) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "CURRENT MEAL",
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF002244),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002244).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Quick Review",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Rate your ${_getMealTypeByTime()} experience",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 44,
                    color: index < _rating ? Colors.orange : Colors.white24,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Add a comment...",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF002244),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "SUBMIT FEEDBACK",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
