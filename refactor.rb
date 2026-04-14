text = File.read('lib/warden_dashboard.dart', mode: 'rt:utf-8')

# 1. Update State Variables
text.sub!(/String\? _wardenCategory;\r?\n  String\? _wardenFeeStatus;\r?\n  String\? _currentWorkingCategory;\r?\n  String\? _selectedDept;/, 'List<String> _assignedHostels = [];')

text.sub!(/final data = doc\.data\(\) as Map<String, dynamic>;\r?\n          debugPrint\("Warden Profile Loaded: Category=\$\{data\['category'\]\}, FeeStatus=\$\{data\['feeStatus'\]\}"\);\r?\n          setState\(\(\) \{\r?\n            _wardenCategory = data\['category'\];\r?\n            _wardenFeeStatus = data\['feeStatus'\];\r?\n            _currentWorkingCategory = _wardenCategory; \r?\n            _isLoading = false;\r?\n          \}\);/, 
  "final data = doc.data() as Map<String, dynamic>;\n          setState(() {\n            if (data['assignedHostels'] != null) {\n              _assignedHostels = List<String>.from(data['assignedHostels']);\n            }\n            if (_assignedHostels.isEmpty && data['assignedHostel'] != null) {\n              _assignedHostels.add(data['assignedHostel']);\n            }\n            _isLoading = false;\n          });")

text.sub!(/if \(_wardenCategory == null \|\| _wardenFeeStatus == null\) \{\r?\n      return Center\(\r?\n        child: Column\(\r?\n          mainAxisAlignment: MainAxisAlignment.center,\r?\n          children: \[\r?\n            const Icon\(Icons.account_box, size: 64, color: Colors.grey\),\r?\n            const SizedBox\(height: 16\),\r?\n            const Text\("Please set up your profile to view requests."\),/, 
  "if (_assignedHostels.isEmpty) {\n      return Center(\n        child: Column(\n          mainAxisAlignment: MainAxisAlignment.center,\n          children: [\n            const Icon(Icons.account_box, size: 64, color: Colors.grey),\n            const SizedBox(height: 16),\n            const Text(\"You are not assigned to any hostels.\"),")

text.sub!('child: _selectedDept == null ? _buildDepartmentGrid() : _buildRequestList(),', 'child: _buildRequestList(),')

# UI Top bar filters
text.sub!(/Row\(\r?\n\s*children: \[\r?\n\s*if \(_selectedDept != null\).*?_currentWorkingCategory == 'Diploma' \? "All Students" : "\$_wardenFeeStatus Students",\r?\n\s*style: const TextStyle\(color: Colors.white70, fontSize: 13\),\r?\n\s*\),\r?\n\s*\],\r?\n\s*\),\r?\n\s*\),\r?\n\s*Row\(\r?\n\s*mainAxisSize: MainAxisSize.min,\r?\n\s*children: \[\r?\n\s*\/\/ Toggle/m, 
  %Q(Row(\n                          children: [\n                            Flexible(\n                              child: Text(\n                                "Warden Dashboard",\n                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),\n                                overflow: TextOverflow.ellipsis,\n                              ),\n                            ),\n                          ],\n                        ),\n                        Text(\n                          "Managing: ${_assignedHostels.join(', ')}",\n                          style: const TextStyle(color: Colors.white70, fontSize: 13),\n                        ),\n                      ],\n                    ),\n                  ),\n                  Row(\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      // Toggle))

text.sub!(/\/\/ Toggle\r?\n\s*FittedBox\(\r?\n.*?\r?\n\s*\),\r?\n\s*\),\r?\n\s*const SizedBox\(width: 6\),\r?\n\s*\/\/ Logout/m, '// Logout')

# Rewrite _buildRequestList
text.sub!(/Widget _buildRequestList\(\) \{.*?Widget _buildCategorySwitchButton/m, <<~DART
  Widget _buildRequestList() {
    Query query = FirebaseFirestore.instance
        .collection('leave_requests')
        .where('wardenStatus', isEqualTo: 'pending')
        .where('status', isEqualTo: 'pending');

    if (_assignedHostels.isNotEmpty) {
      if (_assignedHostels.length <= 10) {
        query = query.where('hostelId', whereIn: _assignedHostels);
      }
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No hostels assigned.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final filteredDocs = snapshot.data?.docs ?? [];
        if (filteredDocs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.done_all, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), const Text("No pending requests", style: TextStyle(color: Colors.grey))]));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildCategorySwitchButton
DART
)

# Unneeded chunks
text.sub!(/Widget _buildDepartmentGrid\(\).*?Widget _buildRequestList/m, 'Widget _buildRequestList')
text.sub!(/Widget _buildCategorySwitchButton\(.*?\).*?Widget _buildRequestCard\(/m, 'Widget _buildRequestCard(')
text.sub!(/\/\/ ============================================================\r?\n\/\/ SCREEN 2: DEPARTMENT SELECTION.*?class WardenProfileTab/m, 'class WardenProfileTab')

# WardenProfileTab Clean up
text.sub!(/String\? _selectedCategory;\r?\n  String\? _selectedFeeStatus;/, '')
text.sub!(/_selectedCategory = data\['category'\];\r?\n            _selectedFeeStatus = data\['feeStatus'\];/, '')
text.sub!(/_buildCategorySelector\(\),\r?\n\s*const SizedBox\(height: 24\),\r?\n\s*_buildFeeStatusSelector\(\),\r?\n\s*const SizedBox\(height: 32\),/, '')
text.sub!(/await doc\.reference\.update\(\{\r?\n\s*'category': _selectedCategory,\r?\n\s*'feeStatus': _selectedFeeStatus,\r?\n\s*\}\);/, "await doc.reference.update({});")
text.sub!(/Widget _buildCategorySelector\(\) \{.*?WardenHeaderClipper/m, "class WardenHeaderClipper")

File.write('lib/warden_dashboard.dart', text, mode: 'wt:utf-8')
