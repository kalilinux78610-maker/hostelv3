import 'package:flutter/material.dart';

/// ╔══════════════════════════════════════════════════════════════╗
/// ║  APP CONFIG — SINGLE FILE TO REBRAND FOR A NEW CLIENT       ║
/// ║                                                              ║
/// ║  To set up a new hostel:                                     ║
/// ║  1. Change values below (name, colors, hostels, branches)    ║
/// ║  2. Replace assets/images/logo.png & building.jpg            ║
/// ║  3. Update firebase_options.dart with new Firebase project   ║
/// ║  4. Build APK → Done!                                        ║
/// ╚══════════════════════════════════════════════════════════════╝

class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ─────────────────────────────────────────────
  //  BRANDING
  // ─────────────────────────────────────────────
  static const String appName = 'SVPES eGate Pass';
  static const String orgName = 'RNGPIT';
  static const String footerText = 'v1.0.0 • RNGPIT Hostel';
  static const String developerCredit = 'RNGPIT Tech Team';

  // ─────────────────────────────────────────────
  //  EMAIL / DOMAIN
  // ─────────────────────────────────────────────
  /// Used by guard scanner to search students by enrollment ID
  static const String emailDomain = 'rngpit.com';
  static const String fallbackEmailDomain = 'gmail.com';

  // ─────────────────────────────────────────────
  //  COLORS — Change these for a new client theme
  // ─────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF002244);
  static const Color primaryDark = Color(0xFF001a33);
  static const Color primaryLight = Color(0xFF003366);
  static const Color seedColor = Color(0xFF800000);
  static const Color scaffoldBg = Color(0xFFEFEFEF);
  static const Color lightBg = Color(0xFFF5F5F5);

  // ─────────────────────────────────────────────
  //  ASSETS
  // ─────────────────────────────────────────────
  static const String logoPath = 'assets/images/logo.png';
  static const String buildingImagePath = 'assets/images/building.jpg';

  // ─────────────────────────────────────────────
  //  HOSTEL CONFIGURATION
  // ─────────────────────────────────────────────
  static const List<String> hostels = [
    "NGP Boy's Hostel",
    "NGPP Boy's Hostel",
    "Nilanbhai Vyas Boys' Hostel",
    "Workshop Boy's Hostel",
    "Workshop Girl's Hostel",
    "Sardar Hostel (Piplawali)",
    "PJMF Girl's Hostel",
  ];

  /// Maps full hostel name → short code used in Firestore
  static const Map<String, String> hostelCodes = {
    "NGP Boy's Hostel": "NGP",
    "NGPP Boy's Hostel": "NGPP",
    "Nilanbhai Vyas Boys' Hostel": "NVBH",
    "Workshop Boy's Hostel": "WBH",
    "Sardar Hostel (Piplawali)": "SH",
    "Workshop Girl's Hostel": "WGH",
    "PJMF Girl's Hostel": "PJMF",
  };

  /// Converts full hostel name to its short code
  static String? getHostelCode(String? fullName) {
    if (fullName == null) return null;
    for (final entry in hostelCodes.entries) {
      if (fullName.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Converts short code to its full hostel name
  static String getFullHostelName(String? code) {
    if (code == null) return 'Unknown Hostel';
    for (final entry in hostelCodes.entries) {
      if (entry.value == code) return entry.key;
    }
    return code; // Fallback to code if not found
  }

  // ─────────────────────────────────────────────
  //  ACADEMIC CONFIGURATION
  // ─────────────────────────────────────────────

  /// Degree branches — RNGPIT (B.TECH + M.Sc. + B.VOC)
  static const List<String> degreeBranches = [
    // ── B.Tech Engineering ────────────────────────
    'Chemical Engineering',
    'Civil Engineering',
    'Computer Science & Engineering',
    'Electrical Engineering',
    'Information Technology',
    'Mechanical Engineering',
    // ── M.Sc. ────────────────────────────────────
    'M.Sc. IT',
    // ── Management ─────────────────────────────
    'Integrated MBA (5 Years)',
    // ── B.Voc ────────────────────────────────────
    'B.Voc - Industrial Chemistry',
    'B.Voc - Production Technology',
    'B.Voc - Animation & VFX',
    'B.Voc - Building and Construction',
    'B.Voc - Software Development',
    'B.Voc - Solar & Renewable Energy',
    'B.Voc - Wealth Management',
  ];

  /// Diploma branches — NGPP
  static const List<String> diplomaBranches = [
    'Computer Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Chemical Engineering',
  ];

  /// All branches combined (used in filters showing all students regardless of category)
  static const List<String> allBranches = [
    // ── Engineering (shared by Degree & Diploma) ──
    'Chemical Engineering',
    'Civil Engineering',
    'Computer Science & Engineering',
    'Electrical Engineering',
    'Information Technology',
    'Mechanical Engineering',
    // ── M.Sc. (Degree only) ───────────────────────
    'M.Sc. IT',
    // ── Management (Degree only) ──────────────────
    'Integrated MBA (5 Years)',
    // ── B.Voc (Degree only) ───────────────────────
    'B.Voc - Industrial Chemistry',
    'B.Voc - Production Technology',
    'B.Voc - Animation & VFX',
    'B.Voc - Building and Construction',
    'B.Voc - Software Development',
    'B.Voc - Solar & Renewable Energy',
    'B.Voc - Wealth Management',
  ];

  /// Returns the correct branch list based on category
  static List<String> getBranchesForCategory(String? category) {
    if (category == 'Diploma') return diplomaBranches;
    return degreeBranches; // Default to Degree
  }

  /// Legacy alias — use allBranches or getBranchesForCategory() instead
  static const List<String> branches = allBranches;

  static const List<String> years = ['1', '2', '3', '4'];
}
