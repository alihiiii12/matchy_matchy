/// Fallback English labels for category / sub-category ids (when API has no name_en).
abstract final class CategoryI18n {
  static const Map<String, String> categoryEn = {
    'occ_eid': 'Eid',
    'occ_wedding': 'Weddings',
    'occ_beach': 'Beach',
    'occ_home': 'Home',
  };

  static const Map<String, String> subCategoryEn = {
    'occ_eid_family': 'Family Eid set',
    'occ_eid_kids': 'Kids',
    'occ_wedding_family': 'Family set',
    'occ_wedding_formal': 'Formal',
    'occ_beach_family': 'Summer family set',
    'occ_beach_kids': 'Kids',
    'occ_home_family': 'Home set',
    'occ_home_lounge': 'Lounge',
  };

  static String resolve({
    required String id,
    required String name,
    String? nameEn,
    required bool english,
    bool isSub = false,
  }) {
    if (!english) return name;
    if (nameEn != null && nameEn.trim().isNotEmpty) return nameEn.trim();
    final map = isSub ? subCategoryEn : categoryEn;
    return map[id] ?? name;
  }
}
