import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/push_notification_service.dart';

class AppSettingsTab extends StatefulWidget {
  const AppSettingsTab({super.key});

  @override
  State<AppSettingsTab> createState() => _AppSettingsTabState();
}

class _AppSettingsTabState extends State<AppSettingsTab> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;

  // Settings values
  bool _maintenanceMode = false;
  int _outingMaxHours = 24;
  String _curfewTime = '21:00';
  String _messBreakfast = '07:30 AM - 09:00 AM';
  String _messLunch = '12:15 PM - 02:00 PM';
  String _messDinner = '07:30 PM - 09:00 PM';

  // Global Broadcast values
  final _broadcastFormKey = GlobalKey<FormState>();
  final _broadcastTitleController = TextEditingController();
  final _broadcastBodyController = TextEditingController();
  String _broadcastTarget = 'all'; // 'all', 'student', 'staff'
  bool _isBroadcasting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _broadcastTitleController.dispose();
    _broadcastBodyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('global').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _outingMaxHours = data['outingMaxHours'] ?? 24;
          _curfewTime = data['curfewTime'] ?? '21:00';
          _messBreakfast = data['messBreakfast'] ?? '07:30 AM - 09:00 AM';
          _messLunch = data['messLunch'] ?? '12:15 PM - 02:00 PM';
          _messDinner = data['messDinner'] ?? '07:30 PM - 09:00 PM';
          _isLoading = false;
        });
      } else {
        // Initialize document with default values if it doesn't exist
        await _firestore.collection('settings').doc('global').set({
          'maintenanceMode': _maintenanceMode,
          'outingMaxHours': _outingMaxHours,
          'curfewTime': _curfewTime,
          'messBreakfast': _messBreakfast,
          'messLunch': _messLunch,
          'messDinner': _messDinner,
        });
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('settings').doc('global').update({
        'maintenanceMode': _maintenanceMode,
        'outingMaxHours': _outingMaxHours,
        'curfewTime': _curfewTime,
        'messBreakfast': _messBreakfast,
        'messLunch': _messLunch,
        'messDinner': _messDinner,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectCurfewTime() async {
    final parts = _curfewTime.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 21 : 21;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF002244)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _curfewTime = '$hourStr:$minuteStr';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (userEmail != 'karanchaudhary9170@gmail.com') {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: const Color(0xFF002244),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 64, color: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Only the system Owner has permission to edit global rules and configurations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF002244)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Global Settings & Rules'),
        backgroundColor: const Color(0xFF002244),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⚙️ SYSTEM STATUS CARD
              _buildSectionHeader('System Control', Icons.developer_mode),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: const Color(0xFF002244),
                        title: const Text(
                          'Maintenance Mode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: const Text(
                          'Restricts student & staff logins during scheduled app upgrades.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _maintenanceMode,
                        onChanged: (val) {
                          setState(() => _maintenanceMode = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ⏱️ GATE RULES CARD
              _buildSectionHeader('Curfew & Outing Rules', Icons.door_sliding),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Daily Late Curfew Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Students returning after $_curfewTime will be flagged as late entry.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002244).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _curfewTime,
                            style: const TextStyle(
                              color: Color(0xFF002244),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        onTap: _selectCurfewTime,
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Max Outing Duration',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Maximum hours allowed per outing.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF002244).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_outingMaxHours hrs',
                              style: const TextStyle(
                                color: Color(0xFF002244),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _outingMaxHours.toDouble(),
                        min: 4,
                        max: 72,
                        divisions: 17,
                        activeColor: const Color(0xFF002244),
                        inactiveColor: Colors.grey.shade300,
                        label: '$_outingMaxHours hours',
                        onChanged: (val) {
                          setState(() {
                            _outingMaxHours = val.round();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🍽️ MESS HOURS CARD
              _buildSectionHeader('Standard Mess Hours', Icons.restaurant),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Breakfast Hours',
                        initialValue: _messBreakfast,
                        icon: Icons.wb_sunny,
                        onSaved: (val) => _messBreakfast = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Lunch Hours',
                        initialValue: _messLunch,
                        icon: Icons.wb_twilight,
                        onSaved: (val) => _messLunch = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Dinner Hours',
                        initialValue: _messDinner,
                        icon: Icons.nights_stay,
                        onSaved: (val) => _messDinner = val ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 📢 GLOBAL BROADCAST PANEL CARD
              _buildSectionHeader('Global Broadcast Panel', Icons.campaign),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _broadcastFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send immediate high-priority push and in-app notifications to users.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        
                        // Target Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _broadcastTarget,
                          decoration: InputDecoration(
                            labelText: 'Target Audience',
                            prefixIcon: const Icon(Icons.people, color: Color(0xFF002244)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Registered Users')),
                            DropdownMenuItem(value: 'student', child: Text('Students Only')),
                            DropdownMenuItem(value: 'staff', child: Text('Staff Only')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _broadcastTarget = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Title Textfield
                        TextFormField(
                          controller: _broadcastTitleController,
                          decoration: InputDecoration(
                            labelText: 'Broadcast Title',
                            prefixIcon: const Icon(Icons.title, color: Color(0xFF002244)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Message Textfield
                        TextFormField(
                          controller: _broadcastBodyController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Broadcast Message',
                            prefixIcon: const Icon(Icons.message, color: Color(0xFF002244)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Message body is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isBroadcasting ? null : _sendBroadcast,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48), // Rose 600
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isBroadcasting
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Send Broadcast',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 💾 SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () {
                    _formKey.currentState!.save();
                    _saveSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 8),
                            Text(
                              'Save Configurations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF002244), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002244),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF002244)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF002244), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Future<void> _sendBroadcast() async {
    if (!_broadcastFormKey.currentState!.validate()) return;

    setState(() => _isBroadcasting = true);

    final title = _broadcastTitleController.text.trim();
    final message = _broadcastBodyController.text.trim();

    try {
      // 1. Fetch target users from Firestore
      Query query = _firestore.collection('users');

      if (_broadcastTarget == 'student') {
        query = query.where('role', isEqualTo: 'student');
      } else if (_broadcastTarget == 'staff') {
        query = query.where('role', whereIn: ['warden', 'rector', 'hod', 'guard', 'mess_manager', 'admin']);
      }

      final querySnapshot = await query.get();
      final usersDocs = querySnapshot.docs;

      if (usersDocs.isEmpty) {
        throw 'No registered users found matching target group.';
      }

      List<String> targetUids = [];
      List<String> tokens = [];

      for (var doc in usersDocs) {
        final data = doc.data() as Map<String, dynamic>;
        targetUids.add(doc.id);
        final token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      // 2. Batched write to 'notifications' collection for in-app feeds
      final batch = _firestore.batch();
      for (final uid in targetUids) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, {
          'title': title,
          'message': message,
          'receiverUid': uid,
          'type': 'system_broadcast',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // 3. Send Push Notifications via PushNotificationService
      final pushService = PushNotificationService();
      int successCount = 0;
      for (final token in tokens) {
        try {
          await pushService.sendNotification(
            title: title,
            body: message,
            toToken: token,
          );
          successCount++;
        } catch (e) {
          debugPrint('Error sending push to token: $e');
        }
      }

      // Clear fields
      _broadcastTitleController.clear();
      _broadcastBodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Broadcast complete! Logged in-app for ${targetUids.length} users and pushed to $successCount devices.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to broadcast: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isBroadcasting = false);
    }
  }
}
