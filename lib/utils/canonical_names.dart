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
      } else if (branch == 'Computer Science' || branch == 'Computer Engineering') {
        return 'CSE';
      } else if (branch == 'Civil') {
        return 'Civil Engineering';
      } else if (branch == 'Electrical') {
        return 'Electrical';
      } else if (branch == 'Chemical') {
        return 'Chemical';
      } else if (branch?.toLowerCase().replaceAll('.', '') == 'bvoc') {
        return 'B.VOC';
      } else if (branch?.toLowerCase().replaceAll(' ', '') == 'bba&mba' || 
                 branch?.toLowerCase() == 'bba' || 
                 branch?.toLowerCase() == 'mba') {
        return 'BBA & MBA';
      }
    } else if (canonicalCategory == 'Diploma') {
      if (branch == 'Computer Science' || branch == 'CSE') {
        return 'Computer Engineering';
      }
      if (branch == 'Mechanical') {
        return 'Mechanical Engineering';
      }
      if (branch == 'Electrical') {
        return 'Electrical Engineering';
      }
      if (branch == 'Chemical') {
        return 'Chemical Engineering';
      }
    }
    return branch;
  }
}
