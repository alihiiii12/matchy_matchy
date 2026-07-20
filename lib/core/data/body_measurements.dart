import 'package:matchy_matchy/core/data/family_member_roles.dart';

/// Body measurement keys (cm) stored in cart/order options.
abstract final class BodyMeasurements {
  static const heightCm = 'height_cm';
  static const shoulderCm = 'shoulder_cm';
  static const chestCm = 'chest_cm';
  static const waistCm = 'waist_cm';
  static const hipsCm = 'hips_cm';
  static const dressLengthCm = 'dress_length_cm';

  static const keys = <String>[
    heightCm,
    shoulderCm,
    chestCm,
    waistCm,
    hipsCm,
    dressLengthCm,
  ];

  static const labelsAr = <String, String>{
    heightCm: 'الطول (سم)',
    shoulderCm: 'عرض الكتفين (سم)',
    chestCm: 'محيط الصدر (سم)',
    waistCm: 'محيط الخصر (سم)',
    hipsCm: 'محيط الورك (سم)',
    dressLengthCm: 'طول الثوب (سم)',
  };

  static const labelsEn = <String, String>{
    heightCm: 'Height (cm)',
    shoulderCm: 'Shoulder (cm)',
    chestCm: 'Chest (cm)',
    waistCm: 'Waist (cm)',
    hipsCm: 'Hips (cm)',
    dressLengthCm: 'Dress length (cm)',
  };

  static String label(String key, {bool english = false}) {
    if (english) return labelsEn[key] ?? key;
    return labelsAr[key] ?? key;
  }

  static Map<String, dynamic> pickFilled(Map<String, String> values) {
    final out = <String, dynamic>{};
    for (final key in keys) {
      final raw = values[key]?.trim() ?? '';
      if (raw.isEmpty) continue;
      final n = num.tryParse(raw);
      out[key] = n ?? raw;
    }
    return out;
  }

  static String formatFromOptions(Map<String, dynamic>? options, {bool english = false}) {
    if (options == null || options.isEmpty) return '';
    final parts = <String>[];
    for (final key in keys) {
      final v = options[key];
      if (v == null || v.toString().trim().isEmpty) continue;
      parts.add('${label(key, english: english)}: $v');
    }
    return parts.join(' · ');
  }

  static String formatMemberOptions(Map<String, dynamic>? options, {bool english = false}) {
    if (options == null || options.isEmpty) return '';
    final parts = <String>[];
    final role = options['piece_role']?.toString();
    if (role != null && role.isNotEmpty) {
      parts.add(FamilyMemberRoles.label(role));
    }
    final gender = options['gender']?.toString();
    if (gender != null && gender.isNotEmpty) {
      parts.add(FamilyMemberRoles.genderLabel(gender));
    }
    final age = options['age'];
    if (age != null && age.toString().isNotEmpty) {
      parts.add(english ? 'Age $age' : 'عمر $age');
    }
    final size = options['size']?.toString();
    if (size != null && size.isNotEmpty) {
      parts.add(english ? 'Size $size' : 'مقاس $size');
    }
    final m = formatFromOptions(options, english: english);
    if (m.isNotEmpty) parts.add(m);
    return parts.join(' · ');
  }
}
