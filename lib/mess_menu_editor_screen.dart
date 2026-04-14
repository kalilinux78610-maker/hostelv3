import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:http/http.dart' as http;

class MessMenuEditorScreen extends StatefulWidget {
  const MessMenuEditorScreen({super.key});

  @override
  State<MessMenuEditorScreen> createState() => _MessMenuEditorScreenState();
}

class _MessMenuEditorScreenState extends State<MessMenuEditorScreen> {
  static const Color _primaryColor = Color(0xFF002244);
  static const String _cloudName = 'ddvpybjyu';
  static const String _uploadPreset = 'RNGPIT';

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final List<String> _meals = ['Breakfast', 'Lunch', 'Dinner'];

  // Text controllers: { 'Monday': { 'Breakfast': controller, ...}, ... }
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  // Image URLs from Firestore: { 'Monday': { 'Breakfast_imageUrl': 'https://...', ...} }
  final Map<String, Map<String, String?>> _imageUrls = {};

  // Uploading state per meal: { 'Monday_Breakfast': true/false }
  final Map<String, bool> _uploadingStates = {};

  bool _isLoading = true;
  bool _isSaving = false;

  // Returns the ISO week number for a given date (1-52/53)
  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
      date.difference(DateTime(date.year, 1, 1)).inDays.toString(),
    ) + 1;
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) return _isoWeekNumber(DateTime(date.year - 1, 12, 31));
    if (woy > 52) {
      final jan1 = DateTime(date.year + 1, 1, 1);
      if (jan1.weekday != DateTime.thursday && jan1.weekday != DateTime.friday) {
        return 1;
      }
    }
    return max(1, woy);
  }

  String get _currentWeekKey {
    final now = DateTime.now();
    return '${now.year}_W${_isoWeekNumber(now)}';
  }

  @override
  void initState() {
    super.initState();
    for (String day in _days) {
      _controllers[day] = {
        'Breakfast': TextEditingController(),
        'Lunch': TextEditingController(),
        'Dinner': TextEditingController(),
      };
      _imageUrls[day] = {
        'Breakfast': null,
        'Lunch': null,
        'Dinner': null,
      };
    }
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('config')
          .doc('mess_menu')
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final savedWeek = data['weekKey'] as String?;

        // New week detected — ask mess manager if they want to reset
        if (savedWeek != null && savedWeek != _currentWeekKey && mounted) {
          final shouldReset = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF002244)),
                  SizedBox(width: 10),
                  Text('New Week!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'A new week has started. The previous week\'s menu and photos are still saved.\n\nWould you like to reset and start fresh for this week?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep Old Menu'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002244),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reset for New Week'),
                ),
              ],
            ),
          );

          if (shouldReset == true) {
            await _resetMenuForNewWeek();
            return;
          }
        }

        // Load existing data into controllers
        for (String day in _days) {
          if (data.containsKey(day)) {
            final dayData = data[day] as Map<String, dynamic>;
            _controllers[day]?['Breakfast']?.text = dayData['Breakfast'] ?? '';
            _controllers[day]?['Lunch']?.text = dayData['Lunch'] ?? '';
            _controllers[day]?['Dinner']?.text = dayData['Dinner'] ?? '';
            if (mounted) {
              setState(() {
                _imageUrls[day]?['Breakfast'] = dayData['Breakfast_imageUrl'];
                _imageUrls[day]?['Lunch'] = dayData['Lunch_imageUrl'];
                _imageUrls[day]?['Dinner'] = dayData['Dinner_imageUrl'];
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetMenuForNewWeek() async {
    try {
      // Clear Firestore — images in Cloudinary become orphaned but are unlinked
      await FirebaseFirestore.instance
          .collection('config')
          .doc('mess_menu')
          .set({'weekKey': _currentWeekKey}); // Reset with only the new week key

      // Clear all local controllers and image URLs
      for (String day in _days) {
        _controllers[day]?['Breakfast']?.clear();
        _controllers[day]?['Lunch']?.clear();
        _controllers[day]?['Dinner']?.clear();
      }
      if (mounted) {
        setState(() {
          for (String day in _days) {
            _imageUrls[day] = {'Breakfast': null, 'Lunch': null, 'Dinner': null};
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu reset for the new week! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(String day, String meal) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text("Choose Image Source", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF002244)),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF002244)),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    final stateKey = '${day}_$meal';
    setState(() => _uploadingStates[stateKey] = true);

    try {
      var bytes = await pickedFile.readAsBytes();
      // Compress
      try {
        final img = img_pkg.decodeImage(bytes);
        if (img != null) {
          final resized = img_pkg.copyResize(img, width: 1024);
          bytes = img_pkg.encodeJpg(resized, quality: 75);
        }
      } catch (_) {}

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'mess_menu'
        ..fields['public_id'] = '${day}_${meal}_${DateTime.now().millisecondsSinceEpoch}';

      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: '$day-$meal.jpg'));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final imageUrl = jsonResponse['secure_url'] as String;

        // Save immediately to Firestore
        await FirebaseFirestore.instance
            .collection('config')
            .doc('mess_menu')
            .set({
          day: {'${meal}_imageUrl': imageUrl}
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() => _imageUrls[day]?[meal] = imageUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$meal photo uploaded! ✅'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingStates[stateKey] = false);
    }
  }

  Future<void> _saveMenuData() async {
    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> dataToSave = {};

      for (String day in _days) {
        final dayMap = <String, dynamic>{
          'Breakfast': _controllers[day]!['Breakfast']!.text.trim(),
          'Lunch': _controllers[day]!['Lunch']!.text.trim(),
          'Dinner': _controllers[day]!['Dinner']!.text.trim(),
        };
        // Preserve existing image URLs
        if (_imageUrls[day]?['Breakfast'] != null) dayMap['Breakfast_imageUrl'] = _imageUrls[day]!['Breakfast'];
        if (_imageUrls[day]?['Lunch'] != null) dayMap['Lunch_imageUrl'] = _imageUrls[day]!['Lunch'];
        if (_imageUrls[day]?['Dinner'] != null) dayMap['Dinner_imageUrl'] = _imageUrls[day]!['Dinner'];
        dataToSave[day] = dayMap;
      }

      await FirebaseFirestore.instance
          .collection('config')
          .doc('mess_menu')
          .set({...dataToSave, 'weekKey': _currentWeekKey}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mess menu updated successfully! ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving menu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (var dayData in _controllers.values) {
      for (var controller in dayData.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Mess Menu"), backgroundColor: _primaryColor, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: _days.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("Edit Mess Menu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: _primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              )
            else
              IconButton(icon: const Icon(Icons.save), tooltip: "Save Text Changes", onPressed: _saveMenuData),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.white70,
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: _days.map((day) => _buildEditorForDay(day)).toList(),
        ),
      ),
    );
  }

  Widget _buildEditorForDay(String day) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...(_meals.asMap().entries.map((entry) {
          final meal = entry.value;
          final colors = [Colors.orange, Colors.green, _primaryColor];
          final icons = [Icons.free_breakfast, Icons.lunch_dining, Icons.dinner_dining];
          return _buildMealCard(day, meal, icons[entry.key], colors[entry.key]);
        })),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveMenuData,
          icon: const Icon(Icons.save),
          label: const Text("Save Menu to Cloud"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMealCard(String day, String meal, IconData icon, Color color) {
    final stateKey = '${day}_$meal';
    final isUploading = _uploadingStates[stateKey] == true;
    final imageUrl = _imageUrls[day]?[meal];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(meal, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                // Upload button
                isUploading
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                    : TextButton.icon(
                        onPressed: () => _pickAndUploadImage(day, meal),
                        icon: Icon(imageUrl != null ? Icons.edit_note : Icons.add_photo_alternate, size: 18, color: color),
                        label: Text(imageUrl != null ? "Change Photo" : "Add Photo", style: TextStyle(fontSize: 13, color: color)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: color.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
              ],
            ),
          ),

          // Image Preview
          if (imageUrl != null)
            ClipRRect(
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Photo", style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => _pickAndUploadImage(day, meal),
              child: Container(
                height: 100,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 6),
                    Text("Tap to add $meal photo", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // Text field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextFormField(
              controller: _controllers[day]![meal],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter $meal items (e.g. Rice, Dal, Sabji)...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
