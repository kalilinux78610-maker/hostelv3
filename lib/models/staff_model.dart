class StaffMember {
  final String id;
  final String name;
  final String role; // 'Guard', 'Cleaner', 'Warden'
  final String mobile;
  final bool isActive;
  final String? assignedShift; // 'Day', 'Night'
  final String? assignedHostel; // e.g., 'NGP', 'SH'
  final List<String>? assignedHostels; // For multi-hostel support (like Wardens)
  final String? assignedCategory; // Legacy support
  final List<String>? assignedCategories; // Multi-category support for Wardens/HODs
  final String? assignedBranch; 
  final List<String>? assignedBranches; 
  final String? email;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.mobile,
    this.isActive = true,
    this.assignedShift,
    this.assignedHostel,
    this.assignedHostels,
    this.assignedCategory,
    this.assignedCategories,
    this.assignedBranch,
    this.assignedBranches,
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
      'assignedHostels': assignedHostels,
      'assignedCategory': assignedCategory,
      'assignedCategories': assignedCategories,
      'assignedBranch': assignedBranch,
      'assignedBranches': assignedBranches,
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
      assignedHostels: map['assignedHostels'] != null ? List<String>.from(map['assignedHostels']) : null,
      assignedCategory: map['assignedCategory'],
      assignedCategories: map['assignedCategories'] != null ? List<String>.from(map['assignedCategories']) : null,
      assignedBranch: map['assignedBranch'],
      assignedBranches: map['assignedBranches'] != null ? List<String>.from(map['assignedBranches']) : null,
      email: map['email'],
    );
  }
}
