class CanonicalNames {
  static String canonicalizeCategory(String? category) {
    if (category == null) return 'Degree';
    if (['BTech', 'MTech', 'BCA', 'MCA'].contains(category)) {
      return 'Degree';
    }
    return category;
  }

  static String canonicalizeBranch(String? branch, String? category) {
    if (branch == null) return 'Unknown';
    final canonicalCategory = canonicalizeCategory(category);

    if (canonicalCategory == 'Degree') {
      if (branch == 'Information Technology') {
        return 'IT & MSC-IT';
      } else if (branch == 'Computer Science') {
        return 'CSE';
      } else if (branch == 'Civil') {
        return 'Civil Engineering';
      }
    } else if (canonicalCategory == 'Diploma') {
      if (branch == 'Computer Science') {
        return 'Computer Engineering';
      }
      if (branch == 'Mechanical') {
        return 'Mechanical Engineering';
      }
      if (branch == 'Electrical') {
        return 'Electrical Engineering';
      }
    }
    return branch;
  }
}
