class StaffMember {
  final String id;
  final String name;
  final String role; // 'Guard', 'Cleaner', 'Warden'
  final String mobile;
  final bool isActive;
  final String? assignedShift; // 'Day', 'Night'
  final String? assignedHostel; // 'BH1', 'GH1', etc.
  final String? email;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.mobile,
    this.isActive = true,
    this.assignedShift,
    this.assignedHostel,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'mobile': mobile,
      'isActive': isActive,
      'assignedShift': assignedShift,
      'assignedHostel': assignedHostel,
      'email': email,
    };
  }

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Staff',
      mobile: map['mobile'] ?? '',
      isActive: map['isActive'] ?? true,
      assignedShift: map['assignedShift'],
      assignedHostel: map['assignedHostel'],
      email: map['email'],
    );
  }
}
