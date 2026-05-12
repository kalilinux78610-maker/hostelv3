class CanonicalNames {
  static String canonicalName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Unknown';
    return name.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CATEGORY (Degree / Diploma)
  // ─────────────────────────────────────────────────────────────────────────
  static String canonicalizeCategory(String? category) {
    if (category == null) return 'Degree';
    final lower = category.trim().toLowerCase();

    if (lower == 'diploma') return 'Diploma';
    if (lower == 'pharmacy') return 'Pharmacy';

    // Everything else → Degree
    // Covers: degree, btech, b.tech, be, b.e, b.voc, bvoc,
    //         mtech, bca, mca, bachelor of technology, etc.
    return 'Degree';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  INSTITUTE → CATEGORY helper
  //  Used by bulk_import to determine category from institute name
  // ─────────────────────────────────────────────────────────────────────────
  static String categoryFromInstitute(String? institute) {
    if (institute == null) return 'Degree';
    final lower = institute.trim().toLowerCase();
    if (lower.contains('ngpp') || lower.contains('diploma')) return 'Diploma';
    return 'Degree'; // RNGPIT, R.N.G. Patel, etc.
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BRANCH — Maps raw CSV values → canonical AppConfig branch names
  // ─────────────────────────────────────────────────────────────────────────
  static String canonicalizeBranch(String? branch, String? category) {
    if (branch == null) return 'Unknown';
    final canonicalCategory = canonicalizeCategory(category);
    final lower = branch.trim().toLowerCase().replaceAll('.', '').trim();

    // ── DEGREE (RNGPIT) ────────────────────────────────────────────────────
    if (canonicalCategory == 'Degree') {
      // Computer Science & Engineering
      if (lower == 'cse' ||
          lower == 'computer science' ||
          lower == 'computer engineering' ||
          lower == 'computer science engineering' ||
          lower == 'computer science & engineering' ||
          lower == 'computer science and engineering' ||
          lower == 'cs') {
        return 'Computer Science & Engineering';
      }
      // Information Technology
      if (lower == 'it' || lower == 'information technology') {
        return 'Information Technology';
      }
      // Mechanical Engineering
      if (lower == 'mech' || lower == 'mechanical' || lower == 'mechanical engineering') {
        return 'Mechanical Engineering';
      }
      // Civil Engineering
      if (lower == 'civil' || lower == 'civil engineering' || lower == 'ce') {
        return 'Civil Engineering';
      }
      // Electrical Engineering
      if (lower == 'ele' ||
          lower == 'elec' ||
          lower == 'electrical' ||
          lower == 'electrical engineering' ||
          lower == 'ee') {
        return 'Electrical Engineering';
      }
      // Chemical Engineering
      if (lower == 'chem' ||
          lower == 'chemical' ||
          lower == 'chemical engineering' ||
          lower == 'ch') {
        return 'Chemical Engineering';
      }
      // M.Sc. IT
      if (lower == 'msc it' ||
          lower == 'msc-it' ||
          lower == 'm sc it' ||
          lower == 'mscit') {
        return 'M.Sc. IT';
      }
      // Pharmacy
      if (lower == 'pharmacy' ||
          lower == 'bpharm' ||
          lower == 'b.pharm' ||
          lower == 'bachelor of pharmacy') {
        return 'Pharmacy';
      }
      // Integrated MBA (5 Years)
      if (lower == 'bba' ||
          lower == 'mba' ||
          lower == 'bba mba' ||
          lower == 'bba & mba' ||
          lower == 'integrated mba' ||
          lower == 'integrated mba 5 years' ||
          lower == 'integrated mba (5 years)' ||
          lower == 'bachelor of business administration' ||
          lower == 'master of business administration') {
        return 'Integrated MBA (5 Years)';
      }
      // B.Voc — Software Development
      if (lower == 'sd' ||
          lower == 'software development' ||
          lower.contains('software dev')) {
        return 'B.Voc - Software Development';
      }
      // B.Voc — Industrial Chemistry
      if (lower.contains('industrial chemistry') || lower == 'ic') {
        return 'B.Voc - Industrial Chemistry';
      }
      // B.Voc — Production Technology
      if (lower.contains('production technology') || lower == 'pt') {
        return 'B.Voc - Production Technology';
      }
      // B.Voc — Animation & VFX
      if (lower.contains('animation') || lower.contains('vfx')) {
        return 'B.Voc - Animation & VFX';
      }
      // B.Voc — Building and Construction
      if (lower.contains('building') || lower.contains('construction') || lower == 'bc') {
        return 'B.Voc - Building and Construction';
      }
      // B.Voc — Solar & Renewable Energy
      if (lower.contains('solar') || lower.contains('renewable')) {
        return 'B.Voc - Solar & Renewable Energy';
      }
      // B.Voc — Wealth Management
      if (lower.contains('wealth') || lower == 'wm') {
        return 'B.Voc - Wealth Management';
      }
      // Generic B.Voc (no sub-specialization in CSV)
      if (lower == 'bvoc' || lower == 'b voc' || lower == 'b-voc') {
        return 'B.Voc - Software Development'; // default B.Voc fallback
      }
    }

    // ── DIPLOMA (NGPP) ─────────────────────────────────────────────────────
    else if (canonicalCategory == 'Diploma') {
      if (lower == 'cse' ||
          lower == 'cs' ||
          lower == 'computer engineering' ||
          lower == 'computer science') {
        return 'Computer Engineering';
      }
      if (lower == 'it' || lower == 'information technology') {
        return 'Information Technology';
      }
      if (lower == 'mech' || lower == 'mechanical' || lower == 'mechanical engineering') {
        return 'Mechanical Engineering';
      }
      if (lower == 'civil' || lower == 'civil engineering' || lower == 'ce') {
        return 'Civil Engineering';
      }
      if (lower == 'ele' ||
          lower == 'elec' ||
          lower == 'electrical' ||
          lower == 'electrical engineering') {
        return 'Electrical Engineering';
      }
      if (lower == 'chem' || lower == 'chemical' || lower == 'chemical engineering') {
        return 'Chemical Engineering';
      }
    }

    // Fallback — return trimmed original value
    return branch.trim();
  }
}
