import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../repositories/notification_repository.dart';
import 'package:intl/intl.dart';

class AttendanceTakingScreen extends StatefulWidget {
  final String hostelId;
  const AttendanceTakingScreen({super.key, required this.hostelId});

  @override
  State<AttendanceTakingScreen> createState() => _AttendanceTakingScreenState();
}

class _AttendanceTakingScreenState extends State<AttendanceTakingScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAlreadySubmitted = false;

  // Filtering states
  String _searchQuery = '';
  String _selectedRoomFilter = 'All';
  String _selectedStatusFilter = 'All';

  // Room expansion states
  final Map<String, bool> _expandedRooms = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _isAlreadySubmitted = false;
    });

    try {
      final savedAttendance = await _attendanceService.getDailyAttendance(
        widget.hostelId,
        _selectedDate,
      );

      // Always fetch the CURRENT list of students to ensure newly added students appear.
      final currentStudents = await _attendanceService.prepareAttendanceList(
        widget.hostelId,
        _selectedDate,
      );

      if (savedAttendance != null) {
        // Merge the saved statuses into the current students list
        for (var student in currentStudents) {
          try {
            final savedRecord = savedAttendance.records.firstWhere((r) => r.studentEmail == student.studentEmail);
            student.status = savedRecord.status;
          } catch (_) {
            // Student wasn't in the saved records (newly added student), keep their default status.
          }
        }
        
        setState(() {
          _records = currentStudents;
          _isAlreadySubmitted = true;
          _isLoading = false;
          _expandedRooms.clear();
        });
      } else {
        setState(() {
          _records = currentStudents;
          _isLoading = false;
          _expandedRooms.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading students: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF002244),
              onPrimary: Colors.white,
              onSurface: Color(0xFF002244),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadStudents();
    }
  }

  void _markAll(AttendanceStatus status) {
    if (_isAlreadySubmitted) return;
    setState(() {
      for (var record in _records) {
        if (record.status != AttendanceStatus.onLeave && record.status != AttendanceStatus.outOnPass) {
          record.status = status;
        }
      }
    });
  }

  Future<void> _submitAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submit Attendance?"),
        content: Text(
          "Are you sure you want to submit attendance for ${widget.hostelId} on ${DateFormat('dd MMM yyyy').format(_selectedDate)}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2463),
              foregroundColor: Colors.white,
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final attendance = DailyAttendance(
        id: _attendanceService.generateDocId(widget.hostelId, _selectedDate),
        hostelId: widget.hostelId,
        date: _selectedDate,
        records: _records,
        takenBy: user?.email ?? 'Unknown',
        timestamp: DateTime.now(),
      );

      await _attendanceService.submitAttendance(attendance);

      int notificationsSent = 0;
      for (var record in _records) {
        if (record.studentUid != null) {
          if (record.status == AttendanceStatus.absent) {
            try {
              await NotificationRepository().sendNotification(
                title: "Attendance Alert",
                message: "You have been marked ABSENT for ${DateFormat('dd MMM').format(_selectedDate)}.",
                receiverUid: record.studentUid!,
                type: 'attendance_alert',
              );
              notificationsSent++;
            } catch (e) {
              debugPrint("Failed to notify absent student: ${record.studentEmail}");
            }
          } else if (record.status == AttendanceStatus.present) {
            try {
              await NotificationRepository().sendNotification(
                title: "Attendance Marked",
                message: "You have been marked PRESENT for ${DateFormat('dd MMM').format(_selectedDate)}.",
                receiverUid: record.studentUid!,
                type: 'attendance_info',
              );
              notificationsSent++;
            } catch (e) {
              debugPrint("Failed to notify present student: ${record.studentEmail}");
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Attendance submitted! Sent $notificationsSent notifications."),
            backgroundColor: Colors.green,
          ),
        );
        _loadStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting attendance: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          children: [
                            const SizedBox(height: 70), // Space for overlapping stats
                            _buildQuickMarkRow(),
                            _buildFiltersRow(),
                            _buildRoomList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 110,
                  left: 0,
                  right: 0,
                  child: _buildStatsRow(),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildSubmitButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF04122B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: -20,
            child: Icon(Icons.assignment_turned_in_outlined, size: 160, color: Colors.white.withAlpha(10)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.canPop(context)) ...[
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4, right: 12),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Take Attendance', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('d MMM yyyy').format(_selectedDate)}  •  ${widget.hostelId}',
                      style: TextStyle(color: Colors.blue[100], fontSize: 13),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int present = _records.where((r) => r.status == AttendanceStatus.present).length;
    int absent = _records.where((r) => r.status == AttendanceStatus.absent).length;
    int locked = _records.where((r) => r.status == AttendanceStatus.onLeave || r.status == AttendanceStatus.outOnPass).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _statCard("Total", _records.length.toString(), Icons.people_alt, Colors.blue)),
          const SizedBox(width: 4),
          Expanded(child: _statCard("Present", present.toString(), Icons.check_circle, Colors.green)),
          const SizedBox(width: 4),
          Expanded(child: _statCard("Absent", absent.toString(), Icons.cancel, Colors.red)),
          const SizedBox(width: 4),
          Expanded(child: _statCard("Leave", locked.toString(), Icons.pie_chart, Colors.indigo)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String count, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
            child: Icon(icon, color: color[400], size: 16),
          ),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF04122B))),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: color[600], fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickMarkRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(30)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text("Quick Mark All:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            InkWell(
              onTap: _isAlreadySubmitted ? null : () => _markAll(AttendanceStatus.present),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text("Mark All Present", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _isAlreadySubmitted ? null : () => _markAll(AttendanceStatus.absent),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 4),
                    Text("Mark All Absent", style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    // Unique rooms
    final rooms = _records.map((e) => e.room).toSet().toList()..sort();
    final roomOptions = ['All', ...rooms];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(40)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search by name or email...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withAlpha(40)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: roomOptions.contains(_selectedRoomFilter) ? _selectedRoomFilter : 'All',
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                      items: roomOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text('Room: $value', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRoomFilter = val!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withAlpha(40)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStatusFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                      items: ['All', 'Present', 'Absent', 'Leave'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text('Status: $value', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedStatusFilter = val!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    // Filter records
    List<AttendanceRecord> filteredRecords = _records.where((r) {
      bool matchesSearch = r.studentName.toLowerCase().contains(_searchQuery) || r.studentEmail.toLowerCase().contains(_searchQuery);
      bool matchesRoom = _selectedRoomFilter == 'All' || r.room == _selectedRoomFilter;
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Present') matchesStatus = r.status == AttendanceStatus.present;
      if (_selectedStatusFilter == 'Absent') matchesStatus = r.status == AttendanceStatus.absent;
      if (_selectedStatusFilter == 'Leave') matchesStatus = r.status == AttendanceStatus.onLeave || r.status == AttendanceStatus.outOnPass;

      return matchesSearch && matchesRoom && matchesStatus;
    }).toList();

    if (filteredRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text("No students found.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ),
      );
    }

    Map<String, List<AttendanceRecord>> groupedRecords = {};
    for (var record in filteredRecords) {
      groupedRecords.putIfAbsent(record.room, () => []).add(record);
    }
    var sortedRooms = groupedRecords.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sortedRooms.map((room) {
          List<AttendanceRecord> roomStudents = groupedRecords[room]!;
          bool isExpanded = _expandedRooms[room] ?? false;
          List<AttendanceRecord> displayStudents = isExpanded ? roomStudents : roomStudents.take(3).toList();
          bool isLastRoom = room == sortedRooms.last;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline inside the card
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                          child: Icon(Icons.home, size: 14, color: Colors.blue[300]),
                        ),
                        if (!isLastRoom)
                          Expanded(
                            child: Container(
                              width: 1,
                              color: Colors.grey.withAlpha(40),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Room Content
                  Expanded(
                    child: Column(
                      children: [
                        // Room Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0450C2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Room $room",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${roomStudents.length} Students",
                                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Student List
                        ...displayStudents.map((student) {
                          return _buildStudentTile(student);
                        }),
                        // View All Button
                        if (roomStudents.length > 3)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedRooms[room] = !isExpanded;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.grey.withAlpha(20))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isExpanded ? "Show less" : "View all ${roomStudents.length} students",
                                    style: const TextStyle(color: Color(0xFF0450C2), fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF0450C2), size: 16),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentTile(AttendanceRecord student) {
    bool isLeave = student.status == AttendanceStatus.onLeave;
    bool isOut = student.status == AttendanceStatus.outOnPass;
    bool isLocked = isLeave || isOut;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF0F4F8),
              child: Text(
                student.studentName.isNotEmpty ? student.studentName.substring(0, 2).toUpperCase() : "?",
                style: const TextStyle(color: Color(0xFF5A45FF), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF04122B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    student.studentEmail,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Toggle Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusPill(
                  icon: Icons.check_circle,
                  label: "Present",
                  isSelected: student.status == AttendanceStatus.present,
                  activeColor: Colors.green,
                  onTap: _isAlreadySubmitted || isLocked ? null : () => setState(() => student.status = AttendanceStatus.present),
                ),
                const SizedBox(width: 4),
                _statusPill(
                  icon: Icons.cancel,
                  label: "Absent",
                  isSelected: student.status == AttendanceStatus.absent,
                  activeColor: Colors.red,
                  onTap: _isAlreadySubmitted || isLocked ? null : () => setState(() => student.status = AttendanceStatus.absent),
                ),
                const SizedBox(width: 4),
                // Leave/Out pill
                _leaveOutPill(isLeave: isLeave, isOut: isOut),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill({required IconData icon, required String label, required bool isSelected, required MaterialColor activeColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        width: 46,
        decoration: BoxDecoration(
          color: isSelected ? activeColor[50] : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? activeColor[400]! : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 12, color: isSelected ? activeColor[700] : Colors.grey[400]),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? activeColor[700] : Colors.grey[400], fontSize: 8, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.visible),
          ],
        ),
      ),
    );
  }

  Widget _leaveOutPill({required bool isLeave, required bool isOut}) {
    Color color = Colors.grey[400]!;
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey[200]!;
    String label = "Leave";
    IconData icon = Icons.remove_circle_outline;

    if (isLeave) {
      color = Colors.purple[700]!;
      bgColor = Colors.purple[50]!;
      borderColor = Colors.purple[200]!;
      label = "Leave";
      icon = Icons.calendar_month;
    } else if (isOut) {
      color = Colors.orange[700]!;
      bgColor = Colors.orange[50]!;
      borderColor = Colors.orange[200]!;
      label = "Out";
      icon = Icons.exit_to_app;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      width: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.visible),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (_isAlreadySubmitted) {
      return ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isAlreadySubmitted = false;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0A2463),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF0A2463)),
          ),
          elevation: 5,
        ),
        icon: const Icon(Icons.edit, size: 20),
        label: const Text("Edit Submitted Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0A2463).withAlpha(80), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2463), Color(0xFF1E40AF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: _isSubmitting
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text("Submit Attendance", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
