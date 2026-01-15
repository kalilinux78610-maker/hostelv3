import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'repositories/notification_repository.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _leaveType = 'Home'; // 'Home' or 'Outing'
  DateTime? _fromDate;
  TimeOfDay? _fromTime;
  DateTime? _toDate;
  TimeOfDay? _toTime;

  bool _isLoading = false;

  Future<void> _pickDate(bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_fromDate ?? now) : (_toDate ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF002244),
            colorScheme: const ColorScheme.light(primary: Color(0xFF002244)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_fromTime ?? now) : (_toTime ?? now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            timePickerTheme: TimePickerThemeData(
              dialHandColor: const Color(0xFF002244),
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF002244)
                    : Colors.grey.shade200,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            colorScheme: const ColorScheme.light(primary: Color(0xFF002244)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromDate == null ||
        _fromTime == null ||
        _toDate == null ||
        _toTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates/times'),
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      _fromDate!.year,
      _fromDate!.month,
      _fromDate!.day,
      _fromTime!.hour,
      _fromTime!.minute,
    );
    final endDateTime = DateTime(
      _toDate!.year,
      _toDate!.month,
      _toDate!.day,
      _toTime!.hour,
      _toTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Fetch User Details for Context (Hostel, Room, Parent Phone)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      final requestRef = await FirebaseFirestore.instance
          .collection('leave_requests')
          .add({
            'uid': user.uid,
            'email': user.email,
            'name': userData['name'] ?? 'Unknown', // Add Name
            'hostelId':
                userData['assignedHostel'], // Critical for Rector filtering
            'room': userData['room'], // Useful for Warden
            'parentContact':
                userData['parentContact'], // Useful for verification
            'type': _leaveType,
            'startDate': Timestamp.fromDate(startDateTime),
            'endDate': Timestamp.fromDate(endDateTime),
            'reason': _reasonController.text.trim(),
            'status': 'pending',
            'wardenStatus': 'pending',
            'rectorStatus': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Send Notification to Warden
      await NotificationRepository().sendNotification(
        title: "New Leave Request",
        message: "${userData['name'] ?? 'Student'} has requested leave.",
        receiverUid: 'warden',
        type: 'leave_request',
        relatedRequestId: requestRef.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request Submitted Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002244);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Apply Details"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Type Toggle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTypeButton("Home", primaryColor)),
                    Expanded(child: _buildTypeButton("Outing", primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start Date & Time
              const Text(
                "Leaving From",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDateTimePicker(
                      label: _fromDate == null
                          ? "Select Date"
                          : "${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}",
                      icon: Icons.calendar_today,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildDateTimePicker(
                      label: _fromTime == null
                          ? "Time"
                          : _fromTime!.format(context),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // End Date & Time
              const Text(
                "Return By",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDateTimePicker(
                      label: _toDate == null
                          ? "Select Date"
                          : "${_toDate!.day}/${_toDate!.month}/${_toDate!.year}",
                      icon: Icons.calendar_today,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildDateTimePicker(
                      label: _toTime == null
                          ? "Time"
                          : _toTime!.format(context),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "Reason",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter the reason...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a reason' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLeaveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SUBMIT REQUEST",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, Color primaryColor) {
    final bool isSelected = _leaveType == type;
    return GestureDetector(
      onTap: () => setState(() => _leaveType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          type,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
