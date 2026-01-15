import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add new staff
  Future<void> addStaff(StaffMember staff) async {
    await _firestore.collection('staff').doc(staff.id).set(staff.toMap());
  }

  // Update staff details
  Future<void> updateStaff(StaffMember staff) async {
    await _firestore.collection('staff').doc(staff.id).update(staff.toMap());
  }

  // Delete staff (or deactivate)
  Future<void> deleteStaff(String id) async {
    await _firestore.collection('staff').doc(id).delete();
  }

  // Get all active staff
  Stream<List<StaffMember>> getAllStaff() {
    return _firestore.collection('staff').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StaffMember.fromMap(doc.data()))
          .toList();
    });
  }

  // Get staff on duty (mock logic for now based on assignedShift)
  Stream<List<StaffMember>> getStaffOnDuty() {
    // In a real app, check time vs shift
    return _firestore
        .collection('staff')
        .where('isActive', isEqualTo: true)
        .where('assignedShift', isNull: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StaffMember.fromMap(doc.data()))
              .toList();
        });
  }
}
