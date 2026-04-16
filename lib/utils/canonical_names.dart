class CanonicalNames {
  static String canonicalName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Unknown';
    return name.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String canonicalizeCategory(String? category) {
    if (category == null) return 'Degree';
    final lower = category.trim().toLowerCase();
    
    if (lower == 'degree' || lower == 'btech' || lower == 'mtech' || lower == 'bca' || lower == 'mca') {
      return 'Degree';
    }
    if (lower == 'diploma') {
      return 'Diploma';
    }
    return 'Degree'; // default fallback
  }

  static String canonicalizeBranch(String? branch, String? category) {
    if (branch == null) return 'Unknown';
    final canonicalCategory = canonicalizeCategory(category);
    final lowerBranch = branch.trim().toLowerCase();

    if (canonicalCategory == 'Degree') {
      if (lowerBranch == 'it' || lowerBranch == 'information technology' || lowerBranch.contains('msc-it')) {
        return 'IT & MSC-IT';
      } else if (lowerBranch == 'computer science' || lowerBranch == 'computer engineering' || lowerBranch == 'cse') {
        return 'CSE';
      } else if (lowerBranch == 'civil' || lowerBranch == 'civil engineering') {
        return 'Civil Engineering';
      } else if (lowerBranch == 'electrical' || lowerBranch == 'electrical engineering') {
        return 'Electrical';
      } else if (lowerBranch == 'chemical' || lowerBranch == 'chemical engineering') {
        return 'Chemical';
      } else if (lowerBranch.replaceAll('.', '') == 'bvoc') {
        return 'B.VOC';
      } else if (lowerBranch.replaceAll(' ', '') == 'bba&mba' || 
                 lowerBranch == 'bba' || 
                 lowerBranch == 'mba') {
        return 'BBA & MBA';
      }
    } else if (canonicalCategory == 'Diploma') {
      if (lowerBranch == 'computer science' || lowerBranch == 'cse' || lowerBranch == 'computer engineering') {
        return 'Computer Engineering';
      }
      if (lowerBranch == 'mechanical' || lowerBranch == 'mechanical engineering') {
        return 'Mechanical Engineering';
      }
      if (lowerBranch == 'electrical' || lowerBranch == 'electrical engineering') {
        return 'Electrical Engineering';
      }
      if (lowerBranch == 'chemical' || lowerBranch == 'chemical engineering') {
        return 'Chemical Engineering';
      }
    }
    return branch.trim();
  }
}
