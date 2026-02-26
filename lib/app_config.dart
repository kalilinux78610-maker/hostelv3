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
  static const String appName = 'Hostel Mate';
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
    'Boys Hostel 1',
    'Boys Hostel 2',
    'Boys Hostel 3',
    'Boys Hostel 4',
    'Girls Hostel 1',
    'Girls Hostel 2',
  ];

  /// Maps full hostel name → short code used in Firestore
  static const Map<String, String> hostelCodes = {
    'Boys Hostel 1': 'BH1',
    'Boys Hostel 2': 'BH2',
    'Boys Hostel 3': 'BH3',
    'Boys Hostel 4': 'BH4',
    'Girls Hostel 1': 'GH1',
    'Girls Hostel 2': 'GH2',
  };

  /// Converts full hostel name to its short code
  static String? getHostelCode(String? fullName) {
    if (fullName == null) return null;
    for (final entry in hostelCodes.entries) {
      if (fullName.contains(entry.key)) return entry.value;
    }
    return null;
  }

  // ─────────────────────────────────────────────
  //  ACADEMIC CONFIGURATION
  // ─────────────────────────────────────────────
  static const List<String> branches = [
    'Computer Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Chemical Engineering',
  ];

  static const List<String> years = ['1', '2', '3', '4'];
}
